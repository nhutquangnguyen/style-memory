-- Add avatar_url column to clients table
ALTER TABLE clients
ADD COLUMN avatar_url TEXT;

-- Add comment to describe the column
COMMENT ON COLUMN clients.avatar_url IS 'URL path to client avatar image stored in Wasabi (format: wasabi:avatars/userId/clientId_timestamp.jpg)';