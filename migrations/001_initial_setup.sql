-- StyleMemory Migration 001: Initial Database Setup
-- Description: Creates all core tables for StyleMemory app with email-based authentication
-- Created: 2025-11-18
-- Run this script in your Supabase SQL Editor

-- Step 1: Drop existing tables if they exist (start fresh)
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS visits CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Step 2: Create user_profiles table
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE,
    email VARCHAR NOT NULL,
    full_name VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id)
);

-- Step 3: Create clients table
CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    full_name VARCHAR NOT NULL,
    phone VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create visits table
CREATE TABLE visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    visit_date TIMESTAMP WITH TIME ZONE NOT NULL,
    service_type VARCHAR,
    notes TEXT,
    products_used TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Create photos table
CREATE TABLE photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    storage_path VARCHAR NOT NULL,
    photo_type VARCHAR NOT NULL CHECK (photo_type IN ('front', 'back', 'left', 'right')),
    file_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 6: Create indexes for better performance
CREATE INDEX clients_user_id_idx ON clients(user_id);
CREATE INDEX visits_client_id_idx ON visits(client_id);
CREATE INDEX visits_user_id_idx ON visits(user_id);
CREATE INDEX photos_visit_id_idx ON photos(visit_id);
CREATE INDEX photos_user_id_idx ON photos(user_id);

-- Step 7: Enable Row Level Security on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- Step 8: Create RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Step 9: Create RLS Policies for clients
CREATE POLICY "Users can view own clients" ON clients
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own clients" ON clients
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own clients" ON clients
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own clients" ON clients
    FOR DELETE USING (auth.uid() = user_id);

-- Step 10: Create RLS Policies for visits
CREATE POLICY "Users can view own visits" ON visits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own visits" ON visits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own visits" ON visits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own visits" ON visits
    FOR DELETE USING (auth.uid() = user_id);

-- Step 11: Create RLS Policies for photos
CREATE POLICY "Users can view own photos" ON photos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own photos" ON photos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos" ON photos
    FOR DELETE USING (auth.uid() = user_id);

-- Step 12: Create updated_at trigger function
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 13: Add triggers for updated_at timestamps
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Step 14: Verification - List all created tables
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('user_profiles', 'clients', 'visits', 'photos')
ORDER BY tablename;

-- Step 15: Verification - Show table structures
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name IN ('user_profiles', 'clients', 'visits', 'photos')
ORDER BY table_name, ordinal_position;