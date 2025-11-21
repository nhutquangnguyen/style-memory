-- Rollback Migration: Remove stores table and related functionality
-- Author: AI Assistant
-- Date: 2024-11-21
-- Description: Rollback script for stores table migration - removes all stores-related database objects

-- !! WARNING !!
-- This rollback script will permanently delete all store data.
-- Make sure you have backups before running this script.

-- ============================================================================
-- 1. DROP TRIGGERS FIRST
-- ============================================================================

-- Drop trigger for auto-updating timestamps
DROP TRIGGER IF EXISTS handle_stores_updated_at ON public.stores;

-- Drop trigger for creating default stores
DROP TRIGGER IF EXISTS create_default_store_for_user ON auth.users;

-- ============================================================================
-- 2. DROP VIEWS
-- ============================================================================

-- Drop views that depend on the stores table
DROP VIEW IF EXISTS public.active_store_roles;
DROP VIEW IF EXISTS public.stores_with_owners;

-- ============================================================================
-- 3. DROP TABLES (IN DEPENDENCY ORDER)
-- ============================================================================

-- Drop user_store_roles table first (has foreign key to stores)
DROP TABLE IF EXISTS public.user_store_roles CASCADE;

-- Drop stores table
DROP TABLE IF EXISTS public.stores CASCADE;

-- ============================================================================
-- 4. DROP FUNCTIONS
-- ============================================================================

-- Drop the functions (only if not used by other tables)
-- Note: handle_updated_at() might be used by other tables, so be careful

-- Drop store-specific functions
DROP FUNCTION IF EXISTS public.handle_new_user_default_store() CASCADE;

-- Uncomment the following line ONLY if no other tables use the updated_at function
-- DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

-- ============================================================================
-- 5. REVOKE PERMISSIONS
-- ============================================================================

-- Revoke permissions (this will error if tables don't exist, but that's okay)
DO $$
BEGIN
    -- Revoke table permissions
    BEGIN
        REVOKE ALL PRIVILEGES ON public.stores FROM authenticated;
    EXCEPTION
        WHEN undefined_table THEN
            -- Table doesn't exist, continue
            NULL;
    END;

    BEGIN
        REVOKE ALL PRIVILEGES ON public.user_store_roles FROM authenticated;
    EXCEPTION
        WHEN undefined_table THEN
            -- Table doesn't exist, continue
            NULL;
    END;

    -- Revoke view permissions
    BEGIN
        REVOKE ALL PRIVILEGES ON public.stores_with_owners FROM authenticated;
    EXCEPTION
        WHEN undefined_object THEN
            -- View doesn't exist, continue
            NULL;
    END;

    BEGIN
        REVOKE ALL PRIVILEGES ON public.active_store_roles FROM authenticated;
    EXCEPTION
        WHEN undefined_object THEN
            -- View doesn't exist, continue
            NULL;
    END;
END $$;

-- ============================================================================
-- 6. CLEAN UP ORPHANED DATA (OPTIONAL)
-- ============================================================================

-- If you added store_id columns to other tables, you might want to remove them
-- Uncomment and modify these lines as needed:

-- ALTER TABLE public.clients DROP COLUMN IF EXISTS store_id;
-- ALTER TABLE public.visits DROP COLUMN IF EXISTS store_id;
-- ALTER TABLE public.staff DROP COLUMN IF EXISTS store_id;
-- ALTER TABLE public.services DROP COLUMN IF EXISTS store_id;

-- ============================================================================
-- ROLLBACK COMPLETE
-- ============================================================================

-- Log successful completion
DO $$
BEGIN
    RAISE NOTICE 'Rollback 20241121000001_create_stores_table completed successfully';
    RAISE NOTICE 'Removed tables: stores, user_store_roles';
    RAISE NOTICE 'Removed views: stores_with_owners, active_store_roles';
    RAISE NOTICE 'Removed triggers and functions';
    RAISE NOTICE 'Revoked permissions';
    RAISE WARNING 'All store data has been permanently deleted!';
END $$;