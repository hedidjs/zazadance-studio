# Admin Panel Access Fix - Step by Step Instructions

## Problem Analysis
The admin panel is getting "Invalid API key" errors when trying to fetch pending user registration requests. This is happening because:

1. The admin app is using the anon key (correct for RLS-based access)
2. The users table needs proper RLS policies to allow admin access
3. An admin user with email 'dev@zazadance.com' needs to exist in both auth.users and public.users tables

## Solution Overview

The admin panel uses RLS (Row Level Security) policies with the anon key, which is the correct approach. We need to:

1. Create an admin user in Supabase Auth
2. Create/update the admin user in the public.users table
3. Set up proper RLS policies that allow this admin user to bypass normal restrictions

## Step-by-Step Fix

### Step 1: Create Admin User in Supabase Auth (Manual)
1. Go to your Supabase Dashboard
2. Navigate to Authentication > Users
3. Click "Add user"
4. Enter:
   - Email: `dev@zazadance.com`
   - Password: (choose a strong password)
   - Confirm the user (set email_confirmed to true)
5. Note down the UUID of this user (you'll see it in the users list)

### Step 2: Run SQL Script to Set Up Database
Execute the SQL script in your Supabase SQL Editor:

**Option A: Complete Setup (Recommended)**
```sql
-- Copy and paste the content from: complete_admin_setup.sql
```

**Option B: Quick Fix (If you just want to fix the immediate issue)**
```sql
-- Copy and paste the content from: admin_quick_fix.sql
```

### Step 3: Verify the Setup
After running the SQL script, verify:

1. Check if admin user exists in both tables:
```sql
-- Check auth user
SELECT id, email, email_confirmed FROM auth.users WHERE email = 'dev@zazadance.com';

-- Check public user
SELECT id, email, role, is_approved, is_active FROM public.users WHERE email = 'dev@zazadance.com';
```

2. Check if RLS policies are created:
```sql
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users';
```

3. Test admin access by checking pending users:
```sql
-- This should show all pending users (what admin should see)
SELECT id, email, name, is_approved, created_at 
FROM public.users 
WHERE is_approved = false 
ORDER BY created_at DESC;
```

### Step 4: Test Admin Panel
1. Open the admin panel in your browser
2. Sign in with the admin credentials (dev@zazadance.com)
3. Navigate to the pending users section
4. You should now see the 3 pending users mentioned in the issue

## Files Created

1. **`supabase/migrations/admin_user_setup.sql`** - Proper migration file for the migration system
2. **`admin_quick_fix.sql`** - Quick fix script that can be run directly
3. **`complete_admin_setup.sql`** - Comprehensive setup script with verification
4. **`admin-rls-policy.sql`** - Original RLS policy file (already existed)

## How the RLS Policies Work

The policies allow admin access by checking:
1. If the current authenticated user (auth.uid()) exists in the public.users table
2. If that user has email 'dev@zazadance.com'
3. If that user has role 'admin'
4. If that user is approved and active

When these conditions are met, the admin can:
- SELECT all users (including unapproved ones)
- UPDATE all users 
- DELETE users (except themselves)

Regular users can still:
- View their own profile
- Update their own profile
- Register new accounts (anon users can INSERT)

## Troubleshooting

### If admin panel still shows "Invalid API key":
1. Verify the anon key in `/admin-app/lib/main.dart` is correct
2. Check Supabase project URL is correct
3. Ensure RLS is enabled on the users table

### If admin can't see pending users:
1. Verify admin user exists in both auth.users and public.users
2. Check that the UUIDs match between the two tables
3. Verify admin user has role='admin', is_approved=true, is_active=true

### If policies aren't working:
1. Check if RLS is enabled: `SELECT * FROM pg_tables WHERE tablename = 'users';`
2. List current policies: `SELECT * FROM pg_policies WHERE tablename = 'users';`
3. Test with a simple query while authenticated as admin

## Security Notes

- The admin user bypasses normal RLS restrictions only for the users table
- Other tables will still respect their individual RLS policies
- The admin cannot delete their own account (safety measure)
- All changes are logged and auditable through Supabase

## Next Steps After Fix

1. Test the admin panel thoroughly
2. Set up additional admin users if needed (using the same pattern)
3. Consider implementing role-based permissions for different admin levels
4. Set up monitoring for admin actions