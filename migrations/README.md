# StyleMemory Database Migrations

This folder contains SQL migration files for the StyleMemory Supabase database.

## Migration Files

### 001_initial_setup.sql
- **Description**: Initial database setup with email-based authentication
- **Created**: 2025-11-18
- **Tables Created**: `user_profiles`, `clients`, `visits`, `photos`
- **Features**: Row Level Security, indexes, triggers, policies

## How to Run Migrations

1. **Open your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Copy and paste the migration file content**
4. **Run the SQL script**
5. **Verify tables were created successfully**

## Migration Naming Convention

Use the format: `XXX_description.sql`

- `XXX` = Sequential number (001, 002, 003, etc.)
- `description` = Brief description of what the migration does
- Example: `002_add_user_preferences.sql`

## Creating New Migrations

When creating new migrations:

1. **Increment the number** (next available number)
2. **Use descriptive names** that explain the change
3. **Include rollback instructions** in comments if needed
4. **Test thoroughly** before applying to production
5. **Document any breaking changes**

## Example Future Migration Names

- `002_add_client_photos_table.sql` - Add client profile photos
- `003_add_appointment_scheduling.sql` - Add appointment system
- `004_add_user_preferences.sql` - Add user settings/preferences
- `005_add_client_notes_history.sql` - Add historical notes tracking

## Notes

- Always backup your database before running migrations
- Test migrations on a development database first
- Migrations should be idempotent (safe to run multiple times)
- Use transactions where appropriate
- Document any manual steps required after migration