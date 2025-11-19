-- Add loved field to visits table
-- This allows users to mark visits as "loved" to indicate they love the result

ALTER TABLE visits
ADD COLUMN loved BOOLEAN DEFAULT FALSE;

-- Add index for better performance when filtering by loved visits
CREATE INDEX idx_visits_loved ON visits(loved);

-- Add index for user-specific loved visits queries
CREATE INDEX idx_visits_user_loved ON visits(user_id, loved);