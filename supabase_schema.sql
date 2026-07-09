-- SQL Schema Setup for Lush Fintech
-- This script creates the tables and sets up secure Row Level Security (RLS) policies.
-- This script is idempotent (safe to run multiple times without causing duplicate policy/trigger errors).
-- Copy and run this inside your Supabase SQL Editor.

-- 1. Create Profiles Table (extends Supabase Auth users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    avatar_url TEXT,
    wallet_balance NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
    paystack_account_number TEXT DEFAULT 'Verify BVN to activate' NOT NULL,
    paystack_bank_name TEXT DEFAULT 'Not Activated' NOT NULL,
    paystack_customer_code TEXT DEFAULT 'UNVERIFIED' NOT NULL,
    loyalty_points INTEGER DEFAULT 0 NOT NULL,
    kyc_verified BOOLEAN DEFAULT false NOT NULL,
    bvn_verified_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1.5. Create Platform Fees Configuration Table
CREATE TABLE IF NOT EXISTS public.fees_config (
    id TEXT PRIMARY KEY DEFAULT 'main',
    electricity_fee NUMERIC(15, 2) DEFAULT 150.00 NOT NULL,
    cable_fee NUMERIC(15, 2) DEFAULT 150.00 NOT NULL,
    transfer_fee NUMERIC(15, 2) DEFAULT 25.00 NOT NULL,
    referral_bonus NUMERIC(15, 2) DEFAULT 100.00 NOT NULL,
    points_rate NUMERIC(15, 4) DEFAULT 0.0100 NOT NULL
);

-- Seed default fees configuration
INSERT INTO public.fees_config (id, electricity_fee, cable_fee, transfer_fee, referral_bonus, points_rate)
VALUES ('main', 150.00, 150.00, 25.00, 100.00, 0.0100)
ON CONFLICT (id) DO NOTHING;


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

-- 5. Enable Row Level Security (RLS) on all tables (safe to run repeatedly)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beneficiaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies (Cleanly drop existing policies and recreate them to prevent duplicate errors)

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow public insert on sign up trigger" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert/upsert their own profile" ON public.profiles;

CREATE POLICY "Users can view their own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert/upsert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Transactions Policies
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON public.transactions;

CREATE POLICY "Users can view their own transactions" 
    ON public.transactions FOR SELECT 
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can insert their own transactions" 
    ON public.transactions FOR INSERT 
    WITH CHECK (auth.uid() = profile_id);

-- Beneficiaries Policies
DROP POLICY IF EXISTS "Users can view their own beneficiaries" ON public.beneficiaries;
DROP POLICY IF EXISTS "Users can manage their own beneficiaries" ON public.beneficiaries;

CREATE POLICY "Users can view their own beneficiaries" 
    ON public.beneficiaries FOR SELECT 
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can manage their own beneficiaries" 
    ON public.beneficiaries FOR ALL 
    USING (auth.uid() = profile_id);

-- Support Tickets Policies
DROP POLICY IF EXISTS "Users can view their own support tickets" ON public.support_tickets;
DROP POLICY IF EXISTS "Users can create support tickets" ON public.support_tickets;

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
    INSERT INTO public.profiles (id, full_name, email, wallet_balance, paystack_account_number, paystack_bank_name, paystack_customer_code, loyalty_points, kyc_verified)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', 'Darlington Nnamdi'),
        new.email,
        0.00,
        'Verify BVN to activate',
        'Not Activated',
        'UNVERIFIED',
        0,
        false
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. Create Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('transactions', 'alerts', 'promos')),
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS on notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = profile_id);


-- 9. Loyalty, Referrals and Settlement Reconciliation Additions

-- Alter profiles to support cashback
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS cashback_balance NUMERIC(15, 2) DEFAULT 0.00 NOT NULL;

-- Referrals table
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    referred_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL UNIQUE,
    reward_amount NUMERIC(15, 2) DEFAULT 100.00 NOT NULL,
    is_completed BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Loyalty Ledgers table
CREATE TABLE IF NOT EXISTS public.loyalty_ledgers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
    points_change INTEGER DEFAULT 0 NOT NULL,
    cashback_change NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('earn_cashback', 'earn_points', 'redeem_points')),
    description TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Settlement Ledger table
CREATE TABLE IF NOT EXISTS public.settlement_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    intake_amount NUMERIC(15, 2) NOT NULL,
    expected_paystack_settlement NUMERIC(15, 2) NOT NULL,
    vtpass_cost NUMERIC(15, 2),
    net_profit NUMERIC(15, 2),
    reconciliation_status TEXT NOT NULL DEFAULT 'pending' CHECK (reconciliation_status IN ('pending', 'matched', 'discrepancy')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_ledgers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_ledger ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Users can view their referrals" ON public.referrals;
CREATE POLICY "Users can view their referrals" ON public.referrals
    FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referred_id);

DROP POLICY IF EXISTS "Users can view their loyalty ledger" ON public.loyalty_ledgers;
CREATE POLICY "Users can view their loyalty ledger" ON public.loyalty_ledgers
    FOR SELECT USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "Admins can view settlement ledger" ON public.settlement_ledger;
CREATE POLICY "Admins can view settlement ledger" ON public.settlement_ledger
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
            AND (email LIKE '%admin%' OR email LIKE '%@paylenses.com')
        )
    );

-- reward_loyalty function
CREATE OR REPLACE FUNCTION public.reward_loyalty(
    user_id UUID,
    cashback_amount NUMERIC(15, 2),
    points_amount INTEGER,
    tx_id UUID,
    tx_description TEXT
) RETURNS VOID AS $$
BEGIN
    -- 1. Update profiles balance & points
    UPDATE public.profiles
    SET cashback_balance = cashback_balance + cashback_amount,
        loyalty_points = loyalty_points + points_amount
    WHERE id = user_id;

    -- 2. Insert into loyalty ledger for cashback
    IF cashback_amount > 0 THEN
        INSERT INTO public.loyalty_ledgers (profile_id, transaction_id, points_change, cashback_change, type, description)
        VALUES (user_id, tx_id, 0, cashback_amount, 'earn_cashback', tx_description);
    END IF;

    -- 3. Insert into loyalty ledger for points
    IF points_amount > 0 THEN
        INSERT INTO public.loyalty_ledgers (profile_id, transaction_id, points_change, cashback_change, type, description)
        VALUES (user_id, tx_id, points_amount, 0, 'earn_points', tx_description);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create Vending Routes Table for Dynamic Provider Switching
CREATE TABLE IF NOT EXISTS public.vending_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_type TEXT NOT NULL,       -- 'Airtime', 'Data', 'Cable TV', 'Electricity'
    network_provider TEXT NOT NULL,   -- 'MTN', 'Airtel', 'Glo', '9mobile', 'Smile', 'Spectranet'
    active_gateway TEXT NOT NULL,     -- 'VTPass', 'ClubKonnect', 'MobiLilla'
    commission_rate NUMERIC(5,4) NOT NULL DEFAULT 0.0200,   -- e.g. 0.0200 = 2% discount
    is_active BOOLEAN DEFAULT true NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.vending_routes ENABLE ROW LEVEL SECURITY;

-- Allow read access for authenticated users, full access for admins only
DROP POLICY IF EXISTS "Allow authenticated read on vending routes" ON public.vending_routes;
CREATE POLICY "Allow authenticated read on vending routes" ON public.vending_routes
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage vending routes" ON public.vending_routes;
CREATE POLICY "Admins can manage vending routes" ON public.vending_routes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE id = auth.uid() 
            AND (email LIKE '%admin%' OR email LIKE '%@paylenses.com')
        )
    );

-- Seed default VTPass routes
INSERT INTO public.vending_routes (service_type, network_provider, active_gateway, commission_rate)
VALUES 
  ('Airtime', 'MTN', 'VTPass', 0.0200),
  ('Airtime', 'Airtel', 'VTPass', 0.0200),
  ('Airtime', 'Glo', 'VTPass', 0.0400),
  ('Airtime', '9mobile', 'VTPass', 0.0300),
  ('Data', 'MTN', 'VTPass', 0.0180),
  ('Data', 'Airtel', 'VTPass', 0.0180),
  ('Data', 'Glo', 'VTPass', 0.0350),
  ('Data', '9mobile', 'VTPass', 0.0300),
  ('Data', 'Smile', 'VTPass', 0.0100),
  ('Data', 'Spectranet', 'VTPass', 0.0100)
ON CONFLICT DO NOTHING;
