-- StyleMemory Migration 009: Simplify Services Table
-- Description: Remove unnecessary columns from services table (keep only name)
-- Created: 2025-11-20

-- Remove extra columns from services table
-- Keep only: id, user_id, name, is_active, created_at, updated_at

-- Drop the extra columns
ALTER TABLE public.services DROP COLUMN IF EXISTS description;
ALTER TABLE public.services DROP COLUMN IF EXISTS price;
ALTER TABLE public.services DROP COLUMN IF EXISTS duration_minutes;

-- Verify the table structure is correct
-- The table should now have only:
-- - id (UUID PRIMARY KEY)
-- - user_id (UUID NOT NULL)
-- - name (TEXT NOT NULL)
-- - is_active (BOOLEAN NOT NULL DEFAULT TRUE)
-- - created_at (TIMESTAMPTZ NOT NULL DEFAULT NOW())
-- - updated_at (TIMESTAMPTZ NOT NULL DEFAULT NOW())