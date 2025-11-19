-- Migration: Add rating column to visits table
-- This adds a rating field (1-5 stars) to track visit satisfaction

-- Add rating column to visits table
ALTER TABLE visits
ADD COLUMN rating INTEGER CHECK (rating >= 1 AND rating <= 5);

-- Add index for rating queries (for analytics)
CREATE INDEX idx_visits_rating ON visits(rating);

-- Add index for rating with staff_id for staff performance analytics
CREATE INDEX idx_visits_staff_rating ON visits(staff_id, rating) WHERE staff_id IS NOT NULL;