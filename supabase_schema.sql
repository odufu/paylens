-- SQL Schema Setup for Lush Fintech
-- This script creates the tables and sets up Row Level Security (RLS) policies.
-- Copy and run this inside the Supabase SQL Editor.

-- 1. Create Profiles Table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    wallet_balance NUMERIC(15, 2) DEFAULT 209891.21 NOT NULL,
    wema_account_number TEXT DEFAULT '3091827364' NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Transactions Table
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    subtitle TEXT NOT NULL,
    amount NUMERIC(15, 2) NOT NULL, -- positive for credits, negative for debits
    category TEXT NOT NULL CHECK (category IN ('transfers', 'bills', 'wallet')),
    status TEXT NOT NULL CHECK (status IN ('success', 'pending', 'failed')),
    reference TEXT NOT NULL UNIQUE,
    provider TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Create Beneficiaries Table
CREATE TABLE IF NOT EXISTS public.beneficiaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    initials TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 4. Create Support Tickets Table
CREATE TABLE IF NOT EXISTS public.support_tickets (
    id TEXT PRIMARY KEY, -- e.g. #TKT-12934
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'escalated' CHECK (status IN ('escalated', 'resolved', 'closed')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 5. Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beneficiaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies

-- Profiles Policies
CREATE POLICY "Users can view their own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Allow public insert on sign up trigger"
    ON public.profiles FOR INSERT
    WITH CHECK (true);

-- Transactions Policies
CREATE POLICY "Users can view their own transactions" 
    ON public.transactions FOR SELECT 
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert their own transactions" 
    ON public.transactions FOR INSERT 
    WITH CHECK (auth.uid() = profile_id);

-- Beneficiaries Policies
CREATE POLICY "Users can view their own beneficiaries" 
    ON public.beneficiaries FOR SELECT 
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can manage their own beneficiaries" 
    ON public.beneficiaries FOR ALL 
    USING (auth.uid() = profile_id);

-- Support Tickets Policies
CREATE POLICY "Users can view their own support tickets" 
    ON public.support_tickets FOR SELECT 
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can create support tickets" 
    ON public.support_tickets FOR INSERT 
    WITH CHECK (auth.uid() = profile_id);

-- 7. Trigger to automatically create a profile entry when a user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, wallet_balance, wema_account_number)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Darlington Nnamdi'),
        new.email,
        209891.21,
        '3091827364'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
