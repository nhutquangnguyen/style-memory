-- Create staff table
CREATE TABLE public.staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    specialty TEXT,
    profile_image_url TEXT,
    hire_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_staff_user_id ON public.staff(user_id);
CREATE INDEX idx_staff_is_active ON public.staff(is_active);
CREATE INDEX idx_staff_name ON public.staff(name);

-- Enable Row Level Security
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only access their own staff
CREATE POLICY "Users can view their own staff" ON public.staff
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own staff" ON public.staff
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own staff" ON public.staff
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own staff" ON public.staff
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger function (if not exists)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for staff table
CREATE TRIGGER handle_staff_updated_at
    BEFORE UPDATE ON public.staff
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Add staff_id to visits table to link visits to staff members
ALTER TABLE public.visits ADD COLUMN staff_id UUID REFERENCES public.staff(id) ON DELETE SET NULL;
CREATE INDEX idx_visits_staff_id ON public.visits(staff_id);