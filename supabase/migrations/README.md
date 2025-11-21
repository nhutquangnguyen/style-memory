# Style Memory - Database Migrations

This directory contains SQL migration files for the Style Memory application's Supabase database.

## Migration Files

### `20241121000001_create_stores_table.sql`
**Purpose:** Creates the stores table and related infrastructure for multi-store management.

**What it creates:**
- `stores` table with RLS policies
- `user_store_roles` table (future feature)
- Automatic triggers for timestamps and default store creation
- Performance indexes
- Helper views for administration

**Features:**
- ✅ Multi-store support per user
- ✅ Row Level Security (RLS) for data isolation
- ✅ Automatic default store creation for new users
- ✅ Future-ready for role-based access (owner/manager/staff)
- ✅ Performance optimized with indexes
- ✅ Audit trails with created_at/updated_at timestamps

### `20241121000001_create_stores_table_rollback.sql`
**Purpose:** Rollback script to undo the stores table migration.

⚠️ **WARNING:** This will permanently delete all store data!

## How to Run Migrations

### Option 1: Using Supabase CLI (Recommended)

```bash
# Run migration
supabase db push

# Or run specific migration
supabase db reset
```

### Option 2: Manual SQL Execution

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `20241121000001_create_stores_table.sql`
5. Click **Run**

### Option 3: Using Supabase Dashboard

1. Open Supabase Dashboard
2. Go to **Database** → **SQL Editor**
3. Click **New Query**
4. Copy the migration file contents
5. Execute the query

## Verification

After running the migration, verify it worked:

```sql
-- Check if stores table exists
SELECT table_name, table_schema
FROM information_schema.tables
WHERE table_name = 'stores';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'stores';

-- Check triggers
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'stores';

-- Test insert (will create a store for your user)
INSERT INTO public.stores (owner_id, name, phone, address)
VALUES (auth.uid(), 'Test Store', '123-456-7890', '123 Test St');
```

## Rollback Instructions

If you need to rollback this migration:

1. **BACKUP YOUR DATA FIRST!**
2. Run the rollback script: `20241121000001_create_stores_table_rollback.sql`

```sql
-- Example backup before rollback
CREATE TABLE stores_backup AS SELECT * FROM public.stores;
CREATE TABLE user_store_roles_backup AS SELECT * FROM public.user_store_roles;
```

## Integration with Flutter App

Once the migration is complete, the Flutter app will automatically:

1. **Detect the new stores table** and start using Supabase instead of SharedPreferences
2. **Migrate existing store data** from local storage to Supabase
3. **Create default stores** for users who don't have any
4. **Sync all store changes** to the cloud

No code changes are needed in the Flutter app - it's already compatible!

## Future Features Enabled

This migration enables these future features:

- **Multi-store management:** Users can own multiple stores
- **Role-based access:** Add managers and staff to stores
- **Store sharing:** Multiple users can access the same store
- **Centralized management:** All store data in one place
- **Cross-device sync:** Store data available on all devices

## Database Schema

```sql
-- Main stores table
stores {
  id UUID (Primary Key)
  owner_id UUID (Foreign Key → auth.users)
  name TEXT (Store name)
  phone TEXT (Phone number)
  address TEXT (Address)
  created_at TIMESTAMPTZ
  updated_at TIMESTAMPTZ
}

-- Future role management
user_store_roles {
  id UUID (Primary Key)
  user_id UUID (Foreign Key → auth.users)
  store_id UUID (Foreign Key → stores)
  role TEXT (owner/manager/staff)
  granted_by UUID (Foreign Key → auth.users)
  granted_at TIMESTAMPTZ
  revoked_at TIMESTAMPTZ
  is_active BOOLEAN
}
```

## Security

- **Row Level Security (RLS)** ensures users can only access their own stores
- **Foreign key constraints** maintain data integrity
- **Cascade deletes** clean up related data when users are deleted
- **Input validation** via database constraints and checks

## Support

If you encounter issues:

1. Check the Supabase logs in the dashboard
2. Verify your user authentication is working
3. Ensure RLS policies are correctly applied
4. Check that the Flutter app has the latest StoresProvider code

## Migration History

| Version | Date | Description |
|---------|------|-------------|
| 20241121000001 | 2024-11-21 | Initial stores table creation with multi-store support |