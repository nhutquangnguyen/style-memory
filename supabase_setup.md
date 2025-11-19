# Supabase Setup Guide for StyleMemory

This guide walks you through setting up the Supabase backend for the StyleMemory app.

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in to your account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `StyleMemory`
   - Database Password: Use a strong password (save this!)
   - Region: Choose the closest to your users
6. Wait for the project to be created (usually 2-3 minutes)

## 2. Database Schema

Copy and paste the following SQL into the Supabase SQL editor:

```sql
-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE,
    email VARCHAR NOT NULL,
    full_name VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (id)
);

-- Create clients table
CREATE TABLE clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    full_name VARCHAR NOT NULL,
    phone VARCHAR,
    email VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create staff table
CREATE TABLE staff (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    specialty VARCHAR,
    phone VARCHAR,
    email VARCHAR,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create services table
CREATE TABLE services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create visits table
CREATE TABLE visits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    staff_id UUID REFERENCES staff(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id) ON DELETE SET NULL,
    visit_date TIMESTAMP WITH TIME ZONE NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    loved BOOLEAN DEFAULT false,
    notes TEXT,
    products_used TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create photos table
CREATE TABLE photos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    visit_id UUID REFERENCES visits(id) ON DELETE CASCADE,
    user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    storage_path VARCHAR NOT NULL,
    photo_type VARCHAR NOT NULL CHECK (photo_type IN ('front', 'back', 'left', 'right')),
    file_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX clients_user_id_idx ON clients(user_id);
CREATE INDEX visits_client_id_idx ON visits(client_id);
CREATE INDEX visits_user_id_idx ON visits(user_id);
CREATE INDEX photos_visit_id_idx ON photos(visit_id);
CREATE INDEX photos_user_id_idx ON photos(user_id);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for clients
CREATE POLICY "Users can view own clients" ON clients
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own clients" ON clients
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own clients" ON clients
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own clients" ON clients
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for visits
CREATE POLICY "Users can view own visits" ON visits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own visits" ON visits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own visits" ON visits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own visits" ON visits
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for photos
CREATE POLICY "Users can view own photos" ON photos
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own photos" ON photos
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos" ON photos
    FOR DELETE USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER handle_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER handle_visits_updated_at
    BEFORE UPDATE ON visits
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();
```

## 3. Storage Setup

1. Go to Storage in your Supabase dashboard
2. Click "Create bucket"
3. Name: `client-photos`
4. Make it Private (not public)
5. Click "Create bucket"

### Storage Policies

Go to Storage > Policies and add these policies for the `client-photos` bucket:

```sql
-- Policy for SELECT (viewing photos)
CREATE POLICY "Users can view own photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'client-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policy for INSERT (uploading photos)
CREATE POLICY "Users can upload own photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'client-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policy for DELETE (deleting photos)
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
USING (bucket_id = 'client-photos' AND auth.uid()::text = (storage.foldername(name))[1]);
```

## 4. Authentication Settings

1. Go to Authentication > Settings in your Supabase dashboard
2. Under "User signups", ensure "Enable email confirmations" is turned OFF for development
3. Under "Auth Providers", make sure "Email" is enabled
4. You can disable other providers if you only want email/password authentication

## 5. Get Your Credentials

1. Go to Settings > API in your Supabase dashboard
2. Copy the following values:
   - Project URL
   - Project anon/public key

## 6. Update Flutter App

Update the `main.dart` file with your Supabase credentials:

```dart
await SupabaseService.initialize(
  supabaseUrl: 'YOUR_SUPABASE_PROJECT_URL',
  supabaseAnonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

## 7. Test the Setup

1. Run the Flutter app
2. Try creating an account
3. Add a client
4. Try capturing photos (simulated in demo)

## Security Notes

- Row Level Security (RLS) is enabled to ensure users can only access their own data
- Storage policies prevent users from accessing other users' photos
- All operations are scoped to the authenticated user
- The storage bucket is private by default

## Troubleshooting

### Common Issues:

1. **Authentication not working**: Check if your Supabase URL and keys are correct
2. **RLS blocking queries**: Make sure policies are set up correctly
3. **Storage upload failing**: Verify storage policies are in place
4. **Database errors**: Check that all tables and indexes were created successfully

### Testing RLS Policies:

You can test RLS policies by running queries in the Supabase SQL editor while authenticated as different users.

## Production Considerations

1. Enable email confirmations for production
2. Set up proper CORS policies
3. Monitor usage and set up billing alerts
4. Consider setting up database backups
5. Review and test all security policies
6. Set up proper logging and monitoring

## Environment Variables (Optional)

For better security in production, consider using environment variables:

```dart
// Create a .env file (add to .gitignore)
SUPABASE_URL=your_url_here
SUPABASE_ANON_KEY=your_key_here

// Use flutter_dotenv package to load them
```

This setup provides a complete backend for the StyleMemory app with proper security, scalability, and data isolation between users.