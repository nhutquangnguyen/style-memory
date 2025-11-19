-- Update existing visits to set loved = false for any NULL values
-- This ensures all existing visits have a proper boolean value

UPDATE visits
SET loved = FALSE
WHERE loved IS NULL;