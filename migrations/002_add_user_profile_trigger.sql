-- StyleMemory Migration 002: Add User Profile Auto-Creation Trigger
-- Description: Automatically creates user profile when auth.users record is created
-- Created: 2025-11-19
-- Run this script in your Supabase SQL Editor after running 001_initial_setup.sql

-- Create function to handle new user profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable RLS on auth.users (if not already enabled)
-- Note: This might already be enabled by Supabase
-- ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- Verification: Check if trigger was created
SELECT
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';