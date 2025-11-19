-- StyleMemory: Fix user_profiles table for email-based authentication
-- Run this script in your Supabase SQL Editor

-- Step 1: Drop existing table and policies to start fresh
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Step 2: Create the new user_profiles table with correct structure
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE,
    email VARCHAR NOT NULL,
    full_name VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id)
);

-- Step 3: Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies that work with auth.uid()
CREATE POLICY "Enable read access for users to their own profile"
ON user_profiles FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Enable insert access for users to their own profile"
ON user_profiles FOR INSERT
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable update access for users to their own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

CREATE POLICY "Enable delete access for users to their own profile"
ON user_profiles FOR DELETE
USING (auth.uid() = id);

-- Step 5: Update the updated_at trigger
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Verification: Check that the table was created successfully
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;