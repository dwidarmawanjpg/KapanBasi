-- 📋 SQL Schema for KapanBasi? Database Setup
-- Run this script in the Supabase SQL Editor (https://supabase.com/dashboard)

-- =========================================================================
-- 1. Table Setup: foods
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
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

-- Create public access policies for foods table
-- Allow anyone to read foods
CREATE POLICY "Allow anonymous read" 
ON public.foods FOR SELECT 
TO public 
USING (true);

-- Allow anyone to insert foods
CREATE POLICY "Allow anonymous insert" 
ON public.foods FOR INSERT 
TO public 
WITH CHECK (true);

-- Allow anyone to update foods
CREATE POLICY "Allow anonymous update" 
ON public.foods FOR UPDATE 
TO public 
USING (true);

-- Allow anyone to delete foods
CREATE POLICY "Allow anonymous delete" 
ON public.foods FOR DELETE 
TO public 
USING (true);


-- =========================================================================
-- 2. Storage Setup: food-images bucket
-- =========================================================================

-- Create the public bucket for food images if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('food-images', 'food-images', true)
ON CONFLICT (id) DO NOTHING;

-- RLS policies for storage bucket 'food-images'
-- Allow public read access to food-images objects
CREATE POLICY "Public Read Access" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'food-images');

-- Allow public write/upload access to food-images objects
CREATE POLICY "Public Upload Access" 
ON storage.objects FOR INSERT 
TO public 
WITH CHECK (bucket_id = 'food-images');

-- Allow public update access to food-images objects
CREATE POLICY "Public Update Access" 
ON storage.objects FOR UPDATE 
TO public 
USING (bucket_id = 'food-images');

-- Allow public delete access to food-images objects
CREATE POLICY "Public Delete Access" 
ON storage.objects FOR DELETE 
TO public 
USING (bucket_id = 'food-images');
