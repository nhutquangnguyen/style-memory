-- StyleMemory Migration 005: Create Storage Bucket (Alternative Method)
-- Description: Creates storage bucket using Supabase Dashboard method
-- Created: 2025-11-19
-- This is an alternative approach - use Supabase Dashboard instead of SQL

-- OPTION 1: Use Supabase Dashboard (Recommended)
-- 1. Go to your Supabase Dashboard
-- 2. Click on "Storage" in the left sidebar
-- 3. Click "New Bucket"
-- 4. Fill in these settings:
--    - Name: client-photos
--    - Public: false (unchecked)
--    - File size limit: 10MB
--    - Allowed MIME types: image/jpeg, image/png, image/webp, image/jpg
-- 5. Click "Create bucket"
-- 6. Go to the bucket and set up RLS policies using the dashboard

-- OPTION 2: If you have supabase CLI, run these commands in terminal:
-- supabase storage buckets create client-photos --public=false
-- supabase storage buckets update client-photos --file-size-limit=10485760

-- After creating the bucket, you can verify it exists with this query:
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'client-photos';

-- Note: Storage RLS policies are typically managed through the Supabase Dashboard
-- under Storage > [bucket name] > Policies
-- The dashboard provides a user-friendly interface for setting up:
-- - Upload policies (users can upload to their own folders)
-- - Download policies (users can access their own files)
-- - Delete policies (users can delete their own files)