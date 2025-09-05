-- Diagnostic queries for terms_content table debugging
-- Run these queries in your Supabase SQL editor to identify issues

-- 1. Check if terms_content table exists
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'terms_content'
) AS table_exists;

-- 2. If table exists, check its structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'terms_content' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check if there are any rows in the table
SELECT 
    COUNT(*) as total_rows,
    COUNT(CASE WHEN content_type = 'disclaimer' THEN 1 END) as disclaimer_rows,
    COUNT(CASE WHEN content_type = 'disclaimer' AND is_active = true THEN 1 END) as active_disclaimer_rows
FROM terms_content;

-- 4. View all disclaimer content
SELECT 
    id,
    content_type,
    title_he,
    LEFT(content_he, 100) as content_preview,
    version,
    effective_date,
    is_active,
    created_at,
    updated_at
FROM terms_content 
WHERE content_type = 'disclaimer'
ORDER BY created_at DESC;

-- 5. Check RLS policies on the table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'terms_content';

-- 6. Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'terms_content';

-- 7. Check for unique constraints that might cause conflicts
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'terms_content'
AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY');

-- 8. Check for any triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'terms_content';

-- 9. Test if current user can insert/update disclaimer content
-- (This will show what permissions the current user has)
SELECT 
    has_table_privilege('terms_content', 'INSERT') as can_insert,
    has_table_privilege('terms_content', 'UPDATE') as can_update,
    has_table_privilege('terms_content', 'SELECT') as can_select,
    has_table_privilege('terms_content', 'DELETE') as can_delete;

-- 10. Check if users table exists and has admin role column
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'users'
) AS users_table_exists;

SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
AND column_name = 'role';