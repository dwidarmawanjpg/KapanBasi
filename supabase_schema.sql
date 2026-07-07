-- 📋 SQL Schema for KapanBasi? Database Setup
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard)

-- =========================================================================
-- 1. Table Setup: profiles
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles
CREATE POLICY "Allow public read access to profiles" 
ON public.profiles FOR SELECT 
TO public 
USING (true);

CREATE POLICY "Allow users to update their own profile" 
ON public.profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id);

CREATE POLICY "Allow users to insert their own profile" 
ON public.profiles FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);


-- =========================================================================
-- 2. Trigger Setup: Automatically create profile on user registration
-- =========================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Pengguna KapanBasi'),
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to execute handle_new_user on signup
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- =========================================================================
-- 3. Table Setup: storage_locations
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.storage_locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL
);

-- Seed default storage locations
INSERT INTO public.storage_locations (id, name) VALUES
('d1', 'Kulkas Bawah'),
('d2', 'Freezer'),
('d3', 'Lemari Dapur'),
('d4', 'Meja Makan')
ON CONFLICT (id) DO NOTHING;

-- Enable RLS for storage_locations
ALTER TABLE public.storage_locations ENABLE ROW LEVEL SECURITY;

-- Allow public read access to storage_locations
CREATE POLICY "Allow public read to storage_locations"
ON public.storage_locations FOR SELECT
TO public
USING (true);


-- =========================================================================
-- 4. Table Setup: foods
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    storage_location TEXT NOT NULL,
    expiry_date DATE NOT NULL,
    purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    image_url TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit TEXT NOT NULL DEFAULT 'pcs',
    is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.foods ENABLE ROW LEVEL SECURITY;

-- Create policies for foods (owner-based access control)
CREATE POLICY "Allow users to read their own foods" 
ON public.foods FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to insert their own foods" 
ON public.foods FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow users to update their own foods" 
ON public.foods FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Allow users to delete their own foods" 
ON public.foods FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);


-- =========================================================================
-- 5. Storage Setup: food-images bucket
-- =========================================================================

-- Create the public bucket for food images if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('food-images', 'food-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage bucket 'food-images'
CREATE POLICY "Public Read Access" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'food-images');

CREATE POLICY "Public Upload Access" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'food-images');

CREATE POLICY "Public Update Access" 
ON storage.objects FOR UPDATE 
TO authenticated 
USING (bucket_id = 'food-images');

CREATE POLICY "Public Delete Access" 
ON storage.objects FOR DELETE 
TO authenticated 
USING (bucket_id = 'food-images');
