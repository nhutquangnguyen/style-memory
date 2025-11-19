-- StyleMemory Migration 003: Manual User Profile Fix
-- Description: Manually create user profile and test the flow
-- Created: 2025-11-19
-- Run this script in your Supabase SQL Editor

-- First, let's check what users exist in auth.users
SELECT id, email, created_at FROM auth.users;

-- Check if any profiles exist
SELECT * FROM user_profiles;

-- If you see users in auth.users but no profiles, run this to create them manually:
-- Replace 'YOUR_USER_ID_HERE' with the actual UUID from auth.users

-- Example (replace with your actual user ID):
-- INSERT INTO user_profiles (id, email, full_name, created_at, updated_at)
-- SELECT
--   id,
--   email,
--   COALESCE(raw_user_meta_data->>'full_name', ''),
--   created_at,
--   NOW()
-- FROM auth.users
-- WHERE id = 'YOUR_USER_ID_HERE'
-- ON CONFLICT (id) DO NOTHING;

-- Or to create profiles for ALL existing users:
INSERT INTO user_profiles (id, email, full_name, created_at, updated_at)
SELECT
  id,
  email,
  COALESCE(raw_user_meta_data->>'full_name', ''),
  created_at,
  NOW()
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Verify profiles were created
SELECT
  up.id,
  up.email,
  up.full_name,
  au.email as auth_email
FROM user_profiles up
JOIN auth.users au ON up.id = au.id;