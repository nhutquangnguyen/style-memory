-- Migration: Add slug, avatar, and cover fields to stores table
-- Author: AI Assistant
-- Date: 2024-11-23
-- Description: Adds slug (URL-friendly identifier), avatar, and cover image fields to stores table

-- ============================================================================
-- 1. ADD NEW COLUMNS TO STORES TABLE
-- ============================================================================

-- Add slug column (URL-friendly store identifier)
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS slug TEXT;

-- Add avatar column (store profile image path)
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS avatar TEXT;

-- Add cover column (store cover/banner image path)
ALTER TABLE public.stores ADD COLUMN IF NOT EXISTS cover TEXT;

-- ============================================================================
-- 2. ADD COLUMN COMMENTS
-- ============================================================================

COMMENT ON COLUMN public.stores.slug IS 'URL-friendly store identifier (e.g., "downtown-hair-salon")';
COMMENT ON COLUMN public.stores.avatar IS 'Store profile/logo image path (stored in Wasabi)';
COMMENT ON COLUMN public.stores.cover IS 'Store cover/banner image path (stored in Wasabi)';

-- ============================================================================
-- 3. CREATE UNIQUE INDEX FOR SLUG
-- ============================================================================

-- Create unique index for slug (to prevent duplicate slugs)
-- Note: Allows NULL values but ensures uniqueness when not NULL
CREATE UNIQUE INDEX IF NOT EXISTS idx_stores_slug_unique ON public.stores(slug)
    WHERE slug IS NOT NULL;

-- Create index for slug queries (even with NULL values)
CREATE INDEX IF NOT EXISTS idx_stores_slug ON public.stores(slug);

-- ============================================================================
-- 4. ADD SLUG VALIDATION FUNCTION
-- ============================================================================

-- Function to validate and generate slugs
CREATE OR REPLACE FUNCTION public.validate_store_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- If slug is provided, validate it
    IF NEW.slug IS NOT NULL THEN
        -- Remove leading/trailing whitespace
        NEW.slug := TRIM(NEW.slug);

        -- If slug is empty string, set to NULL
        IF NEW.slug = '' THEN
            NEW.slug := NULL;
        ELSE
            -- Validate slug format (alphanumeric, hyphens, underscores only)
            IF NEW.slug !~ '^[a-zA-Z0-9_-]+$' THEN
                RAISE EXCEPTION 'Invalid slug format. Only letters, numbers, hyphens, and underscores are allowed.';
            END IF;

            -- Convert to lowercase
            NEW.slug := LOWER(NEW.slug);

            -- Check minimum length
            IF LENGTH(NEW.slug) < 3 THEN
                RAISE EXCEPTION 'Slug must be at least 3 characters long.';
            END IF;

            -- Check maximum length
            IF LENGTH(NEW.slug) > 50 THEN
                RAISE EXCEPTION 'Slug cannot be longer than 50 characters.';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Add comment to function
COMMENT ON FUNCTION public.validate_store_slug() IS 'Validates and normalizes store slug format';

-- ============================================================================
-- 5. CREATE TRIGGER FOR SLUG VALIDATION
-- ============================================================================

-- Create trigger to validate slug on insert/update
CREATE TRIGGER validate_store_slug_trigger
    BEFORE INSERT OR UPDATE ON public.stores
    FOR EACH ROW
    EXECUTE FUNCTION public.validate_store_slug();

-- ============================================================================
-- 6. ADD HELPER FUNCTION TO GENERATE SLUG FROM NAME
-- ============================================================================

-- Function to generate slug from store name
CREATE OR REPLACE FUNCTION public.generate_slug_from_name(store_name TEXT)
RETURNS TEXT AS $$
DECLARE
    base_slug TEXT;
    final_slug TEXT;
    counter INTEGER := 0;
BEGIN
    -- Convert name to slug format
    base_slug := LOWER(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                TRIM(store_name),
                '[^a-zA-Z0-9\s-]', '', 'g'  -- Remove special characters
            ),
            '\s+', '-', 'g'  -- Replace spaces with hyphens
        )
    );

    -- Remove leading/trailing hyphens
    base_slug := TRIM(base_slug, '-');

    -- Ensure minimum length
    IF LENGTH(base_slug) < 3 THEN
        base_slug := 'store-' || base_slug;
    END IF;

    -- Ensure maximum length
    IF LENGTH(base_slug) > 45 THEN
        base_slug := LEFT(base_slug, 45);
    END IF;

    -- Check if slug already exists and add counter if needed
    final_slug := base_slug;
    WHILE EXISTS (SELECT 1 FROM public.stores WHERE slug = final_slug) LOOP
        counter := counter + 1;
        final_slug := base_slug || '-' || counter;

        -- Ensure we don't exceed max length with counter
        IF LENGTH(final_slug) > 50 THEN
            base_slug := LEFT(base_slug, 50 - LENGTH('-' || counter));
            final_slug := base_slug || '-' || counter;
        END IF;
    END LOOP;

    RETURN final_slug;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Add comment to function
COMMENT ON FUNCTION public.generate_slug_from_name(TEXT) IS 'Generates a unique slug from store name';

-- ============================================================================
-- 7. UPDATE STORES_WITH_OWNERS VIEW
-- ============================================================================

-- Drop the existing view first
DROP VIEW IF EXISTS public.stores_with_owners;

-- Recreate the view to include new fields
CREATE VIEW public.stores_with_owners AS
SELECT
    s.id,
    s.owner_id,
    s.name,
    s.phone,
    s.address,
    s.slug,
    s.avatar,
    s.cover,
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

-- ============================================================================
-- 8. CREATE SLUG MANAGEMENT FUNCTIONS FOR APP
-- ============================================================================

-- Function for app to check slug availability
CREATE OR REPLACE FUNCTION public.check_slug_availability(check_slug TEXT, store_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
    -- Validate slug format first
    IF check_slug IS NULL OR TRIM(check_slug) = '' THEN
        RETURN FALSE;
    END IF;

    check_slug := LOWER(TRIM(check_slug));

    -- Check format
    IF check_slug !~ '^[a-zA-Z0-9_-]+$' OR LENGTH(check_slug) < 3 OR LENGTH(check_slug) > 50 THEN
        RETURN FALSE;
    END IF;

    -- Check if slug exists (excluding current store if updating)
    IF store_id IS NOT NULL THEN
        RETURN NOT EXISTS (
            SELECT 1 FROM public.stores
            WHERE slug = check_slug AND id != store_id
        );
    ELSE
        RETURN NOT EXISTS (
            SELECT 1 FROM public.stores
            WHERE slug = check_slug
        );
    END IF;
END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public;

-- Add comment to function
COMMENT ON FUNCTION public.check_slug_availability(TEXT, UUID) IS 'Checks if a slug is available for use';

-- ============================================================================
-- 9. GRANT PERMISSIONS FOR NEW FUNCTIONS
-- ============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.generate_slug_from_name(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_slug_availability(TEXT, UUID) TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Log successful completion
DO $$
BEGIN
    RAISE NOTICE 'Migration 012_add_store_slug_avatar_cover completed successfully';
    RAISE NOTICE 'Added columns: slug, avatar, cover to stores table';
    RAISE NOTICE 'Created slug validation and generation functions';
    RAISE NOTICE 'Updated stores_with_owners view';
    RAISE NOTICE 'Added unique index for slug field';
END $$;