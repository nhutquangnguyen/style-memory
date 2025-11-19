-- StyleMemory Migration 006: Storage Policies for client-photos bucket
-- Description: Creates RLS policies for the client-photos storage bucket
-- Created: 2025-11-19
-- Run this AFTER creating the 'client-photos' bucket through Supabase Dashboard

-- Prerequisites:
-- 1. Create 'client-photos' bucket via Supabase Dashboard first
-- 2. Make sure the bucket is private (not public)

-- Step 1: Enable RLS on storage.objects table (may already be enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 2: Create policy for users to upload photos to their own folders
-- Path format: user_id/visit_id/photo.jpg
CREATE POLICY "Users can upload client photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Step 3: Create policy for users to view their own photos
CREATE POLICY "Users can view own client photos" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Step 4: Create policy for users to delete their own photos
CREATE POLICY "Users can delete own client photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Step 5: Create policy for users to update their own photos (optional)
CREATE POLICY "Users can update own client photos" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (string_to_array(name, '/'))[1]
  );

-- Step 6: Verification - Check if policies were created
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'storage'
  AND tablename = 'objects'
  AND policyname LIKE '%client photos%';

-- Step 7: Test query - Check if bucket exists
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'client-photos';

-- Note: If you get permission errors, you can also create these policies
-- through the Supabase Dashboard:
-- 1. Go to Storage > client-photos > Policies
-- 2. Click "Add Policy"
-- 3. Use these templates:
--
-- For INSERT (Upload):
-- Target roles: authenticated
-- Using expression: bucket_id = 'client-photos' AND auth.uid()::text = (string_to_array(name, '/'))[1]
--
-- For SELECT (Download):
-- Target roles: authenticated
-- Using expression: bucket_id = 'client-photos' AND auth.uid()::text = (string_to_array(name, '/'))[1]
--
-- For DELETE:
-- Target roles: authenticated
-- Using expression: bucket_id = 'client-photos' AND auth.uid()::text = (string_to_array(name, '/'))[1]