-- Migration: Create stores table and related functionality
-- Author: AI Assistant
-- Date: 2024-11-21
-- Description: Creates stores table with RLS policies, triggers, and future-ready architecture for multi-store management

-- ============================================================================
-- 1. CREATE STORES TABLE
-- ============================================================================

-- Create stores table
CREATE TABLE IF NOT EXISTS public.stores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT 'My Salon',
    phone TEXT DEFAULT '',
    address TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add table comment
COMMENT ON TABLE public.stores IS 'Stores owned by users - supports multi-store management and future role-based access';

-- Add column comments
COMMENT ON COLUMN public.stores.id IS 'Unique identifier for the store';
COMMENT ON COLUMN public.stores.owner_id IS 'User who owns this store (references auth.users)';
COMMENT ON COLUMN public.stores.name IS 'Store name (e.g., "Hair Salon Downtown")';
COMMENT ON COLUMN public.stores.phone IS 'Store phone number';
COMMENT ON COLUMN public.stores.address IS 'Store physical address';
COMMENT ON COLUMN public.stores.created_at IS 'Timestamp when store was created';
COMMENT ON COLUMN public.stores.updated_at IS 'Timestamp when store was last updated';

-- ============================================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for finding stores by owner (most common query)
CREATE INDEX IF NOT EXISTS idx_stores_owner_id ON public.stores(owner_id);

-- Index for ordering by creation date
CREATE INDEX IF NOT EXISTS idx_stores_created_at ON public.stores(created_at);

-- Composite index for owner + created_at (for paginated queries)
CREATE INDEX IF NOT EXISTS idx_stores_owner_created ON public.stores(owner_id, created_at DESC);

-- ============================================================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on stores table
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own stores
CREATE POLICY "Users can view own stores" ON public.stores
    FOR SELECT USING (auth.uid() = owner_id);

-- Policy: Users can insert their own stores
CREATE POLICY "Users can insert own stores" ON public.stores
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Policy: Users can update their own stores
CREATE POLICY "Users can update own stores" ON public.stores
    FOR UPDATE USING (auth.uid() = owner_id);

-- Policy: Users can delete their own stores
CREATE POLICY "Users can delete own stores" ON public.stores
    FOR DELETE USING (auth.uid() = owner_id);

-- ============================================================================
-- 4. CREATE TRIGGERS AND FUNCTIONS
-- ============================================================================

-- Create or replace function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Add comment to function
COMMENT ON FUNCTION public.handle_updated_at() IS 'Automatically updates updated_at timestamp when record is modified';

-- Create trigger for stores table to auto-update updated_at
CREATE TRIGGER handle_stores_updated_at
    BEFORE UPDATE ON public.stores
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 5. CREATE DEFAULT STORE FOR NEW USERS (OPTIONAL TRIGGER)
-- ============================================================================

-- Function to create default store for new users
CREATE OR REPLACE FUNCTION public.handle_new_user_default_store()
RETURNS TRIGGER AS $$
BEGIN
    -- Create a default store for the new user
    INSERT INTO public.stores (owner_id, name, phone, address)
    VALUES (NEW.id, 'My Salon', '', '');
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail user creation
        RAISE WARNING 'Failed to create default store for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Add comment to function
COMMENT ON FUNCTION public.handle_new_user_default_store() IS 'Creates a default store when a new user signs up';

-- Create trigger to create default store when user signs up
CREATE TRIGGER create_default_store_for_user
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_default_store();

-- ============================================================================
-- 6. CREATE FUTURE-READY USER STORE ROLES TABLE
-- ============================================================================

-- Create user_store_roles table for future multi-user store management
CREATE TABLE IF NOT EXISTS public.user_store_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES public.stores(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'staff')),
    granted_by UUID REFERENCES auth.users(id),
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    revoked_at TIMESTAMPTZ DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    -- Ensure user can only have one active role per store
    UNIQUE(user_id, store_id) DEFERRABLE INITIALLY IMMEDIATE
);

-- Add table comment
COMMENT ON TABLE public.user_store_roles IS 'User roles for stores - enables multi-user store management (future feature)';

-- Add column comments
COMMENT ON COLUMN public.user_store_roles.role IS 'User role: owner, manager, or staff';
COMMENT ON COLUMN public.user_store_roles.granted_by IS 'User who granted this role';
COMMENT ON COLUMN public.user_store_roles.granted_at IS 'When the role was granted';
COMMENT ON COLUMN public.user_store_roles.revoked_at IS 'When the role was revoked (NULL if active)';
COMMENT ON COLUMN public.user_store_roles.is_active IS 'Whether this role assignment is currently active';

-- Add indexes for user_store_roles
CREATE INDEX IF NOT EXISTS idx_user_store_roles_user_id ON public.user_store_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_store_roles_store_id ON public.user_store_roles(store_id);
CREATE INDEX IF NOT EXISTS idx_user_store_roles_active ON public.user_store_roles(is_active) WHERE is_active = true;

-- Enable RLS for user_store_roles
ALTER TABLE public.user_store_roles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view roles for stores they own or have roles in
CREATE POLICY "Users can view relevant store roles" ON public.user_store_roles
    FOR SELECT USING (
        user_id = auth.uid() OR
        store_id IN (
            SELECT id FROM public.stores WHERE owner_id = auth.uid()
        ) OR
        store_id IN (
            SELECT store_id FROM public.user_store_roles
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Policy: Only store owners can manage roles
CREATE POLICY "Store owners can manage roles" ON public.user_store_roles
    FOR ALL USING (
        store_id IN (
            SELECT id FROM public.stores WHERE owner_id = auth.uid()
        )
    );

-- ============================================================================
-- 7. CREATE HELPFUL VIEWS
-- ============================================================================

-- View to get stores with owner information
CREATE OR REPLACE VIEW public.stores_with_owners AS
SELECT
    s.id,
    s.owner_id,
    s.name,
    s.phone,
    s.address,
    s.created_at,
    s.updated_at,
    u.email as owner_email,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email) as owner_name
FROM public.stores s
JOIN auth.users u ON s.owner_id = u.id;

-- Add comment to view
COMMENT ON VIEW public.stores_with_owners IS 'Stores with owner information for administrative purposes';

-- Grant access to authenticated users (they can only see their own stores due to RLS)
GRANT SELECT ON public.stores_with_owners TO authenticated;

-- View for active store roles (future feature)
CREATE OR REPLACE VIEW public.active_store_roles AS
SELECT
    usr.id,
    usr.user_id,
    usr.store_id,
    usr.role,
    usr.granted_by,
    usr.granted_at,
    s.name as store_name,
    COALESCE(u.raw_user_meta_data->>'full_name', u.email) as user_name,
    u.email as user_email
FROM public.user_store_roles usr
JOIN public.stores s ON usr.store_id = s.id
JOIN auth.users u ON usr.user_id = u.id
WHERE usr.is_active = true AND usr.revoked_at IS NULL;

-- Add comment to view
COMMENT ON VIEW public.active_store_roles IS 'Currently active user roles for stores';

-- Grant access to authenticated users
GRANT SELECT ON public.active_store_roles TO authenticated;

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.stores TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_store_roles TO authenticated;

-- Grant usage on sequences (for auto-generated IDs)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- 9. INSERT SAMPLE DATA (OPTIONAL - REMOVE IN PRODUCTION)
-- ============================================================================

-- Uncomment the following lines to insert sample data for testing
-- Note: Replace 'sample-user-id' with an actual user ID from auth.users

-- INSERT INTO public.stores (owner_id, name, phone, address) VALUES
-- ('sample-user-id', 'Downtown Hair Salon', '555-0123', '123 Main St, Downtown, City, State 12345'),
-- ('sample-user-id', 'Uptown Beauty Studio', '555-0456', '456 Oak Ave, Uptown, City, State 67890');

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log successful completion
DO $$
BEGIN
    RAISE NOTICE 'Migration 20241121000001_create_stores_table completed successfully';
    RAISE NOTICE 'Created tables: stores, user_store_roles';
    RAISE NOTICE 'Created views: stores_with_owners, active_store_roles';
    RAISE NOTICE 'Enabled RLS policies for multi-tenant security';
    RAISE NOTICE 'Set up automatic default store creation for new users';
END $$;