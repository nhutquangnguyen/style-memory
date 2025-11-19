-- StyleMemory Migration 004: Create Storage Bucket for Client Photos
-- Description: Creates the storage bucket for client photos with proper security policies
-- Created: 2025-11-19
-- Run this script in your Supabase SQL Editor after running previous migrations

-- Step 1: Create the storage bucket for client photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'client-photos',
  'client-photos',
  false, -- Not public (requires authentication)
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- Step 2: Create RLS policy for bucket access
-- Users can only access their own photos
CREATE POLICY "Users can upload their own photos" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view their own photos" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own photos" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'client-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Step 3: Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 4: Verification - Check if bucket was created
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'client-photos';

-- Step 5: Show the storage policies
SELECT schemaname, tablename, policyname, roles
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
AND policyname LIKE '%photos%';