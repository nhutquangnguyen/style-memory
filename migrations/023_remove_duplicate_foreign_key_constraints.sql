-- Migration 023: Remove Duplicate Foreign Key Constraints
-- Description: Removes duplicate foreign key constraints that cause Supabase query ambiguity
-- Created: 2025-11-23
-- Issue: Multiple constraints on same columns cause "more than one relationship was found" errors

-- ============================================================================
-- IMPORTANT: This migration removes duplicate foreign key constraints
-- It keeps the newer "fk_*" naming convention and removes legacy "*_fkey" ones
-- ============================================================================

-- Step 1: Remove duplicate constraints from CLIENTS table
DO $$
BEGIN
    -- Drop legacy constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'clients_user_id_fkey'
        AND table_name = 'clients'
    ) THEN
        ALTER TABLE clients DROP CONSTRAINT clients_user_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: clients_user_id_fkey';
    END IF;
END $$;

-- Step 2: Remove duplicate constraints from PHOTOS table
DO $$
BEGIN
    -- Drop legacy user_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'photos_user_id_fkey'
        AND table_name = 'photos'
    ) THEN
        ALTER TABLE photos DROP CONSTRAINT photos_user_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: photos_user_id_fkey';
    END IF;

    -- Drop legacy visit_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'photos_visit_id_fkey'
        AND table_name = 'photos'
    ) THEN
        ALTER TABLE photos DROP CONSTRAINT photos_visit_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: photos_visit_id_fkey';
    END IF;
END $$;

-- Step 3: Remove duplicate constraints from USER_STORE_ROLES table
DO $$
BEGIN
    -- Drop legacy store_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'user_store_roles_store_id_fkey'
        AND table_name = 'user_store_roles'
    ) THEN
        ALTER TABLE user_store_roles DROP CONSTRAINT user_store_roles_store_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: user_store_roles_store_id_fkey';
    END IF;
END $$;

-- Step 4: Remove duplicate constraints from VISITS table
DO $$
BEGIN
    -- Drop legacy client_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'visits_client_id_fkey'
        AND table_name = 'visits'
    ) THEN
        ALTER TABLE visits DROP CONSTRAINT visits_client_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: visits_client_id_fkey';
    END IF;

    -- Drop legacy service_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'visits_service_id_fkey'
        AND table_name = 'visits'
    ) THEN
        ALTER TABLE visits DROP CONSTRAINT visits_service_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: visits_service_id_fkey';
    END IF;

    -- Drop legacy staff_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'visits_staff_id_fkey'
        AND table_name = 'visits'
    ) THEN
        ALTER TABLE visits DROP CONSTRAINT visits_staff_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: visits_staff_id_fkey';
    END IF;

    -- Drop legacy user_id constraint if exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'visits_user_id_fkey'
        AND table_name = 'visits'
    ) THEN
        ALTER TABLE visits DROP CONSTRAINT visits_user_id_fkey;
        RAISE NOTICE 'Dropped duplicate constraint: visits_user_id_fkey';
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION: Confirm remaining constraints are correct
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Migration 023 completed successfully';
    RAISE NOTICE 'Removed 8 duplicate foreign key constraints';
    RAISE NOTICE 'Remaining constraints use standardized "fk_*" naming convention';
    RAISE NOTICE 'This should resolve Supabase relationship ambiguity errors';
END $$;

-- ============================================================================
-- POST-MIGRATION VALIDATION (Optional)
-- ============================================================================

-- Uncomment below to validate constraint cleanup
-- SELECT
--     tc.table_name,
--     tc.constraint_name,
--     kcu.column_name,
--     ccu.table_name AS foreign_table_name,
--     ccu.column_name AS foreign_column_name
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
-- AND tc.table_name IN ('clients', 'photos', 'user_store_roles', 'visits')
-- ORDER BY tc.table_name, tc.constraint_name;