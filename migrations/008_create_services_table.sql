-- StyleMemory Migration 008: Create Services Table
-- Description: Creates services table for managing service types and pricing
-- Created: 2025-11-20

-- Create services table (simplified - only service name needed)
CREATE TABLE public.services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_services_user_id ON public.services(user_id);
CREATE INDEX idx_services_is_active ON public.services(is_active);
CREATE INDEX idx_services_name ON public.services(name);

-- Enable Row Level Security
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only access their own services
CREATE POLICY "Users can view their own services" ON public.services
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own services" ON public.services
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own services" ON public.services
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own services" ON public.services
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger for services table
CREATE TRIGGER handle_services_updated_at
    BEFORE UPDATE ON public.services
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Add service_id to visits table to link visits to services
ALTER TABLE public.visits ADD COLUMN service_id UUID REFERENCES public.services(id) ON DELETE SET NULL;
CREATE INDEX idx_visits_service_id ON public.visits(service_id);

-- Remove old service_type column (if it exists)
-- First check if the column exists to avoid errors if migration is run multiple times
DO $$
BEGIN
    IF EXISTS(SELECT * FROM information_schema.columns WHERE table_name='visits' and column_name='service_type') THEN
        ALTER TABLE public.visits DROP COLUMN service_type;
    END IF;
END $$;