-- Fix script for terms_content editing issues
-- Run this in your Supabase SQL editor after running the diagnostics

-- Step 1: Create the table if it doesn't exist (using the migration file content)
-- This is safe to run - it uses IF NOT EXISTS
CREATE TABLE IF NOT EXISTS terms_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('terms', 'privacy', 'disclaimer')),
    title_he TEXT NOT NULL,
    title_en TEXT,
    content_he TEXT NOT NULL,
    content_en TEXT,
    version VARCHAR(20) DEFAULT '1.0',
    effective_date DATE DEFAULT CURRENT_DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Step 2: Drop and recreate the unique constraint to avoid conflicts
DROP INDEX IF EXISTS idx_terms_content_unique_active;
CREATE UNIQUE INDEX idx_terms_content_unique_active 
ON terms_content (content_type) 
WHERE is_active = true;

-- Step 3: Enable RLS and drop existing policies to start fresh
ALTER TABLE terms_content ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read access for active content" ON terms_content;
DROP POLICY IF EXISTS "Allow admin full access" ON terms_content;

-- Step 4: Create more permissive policies for debugging
-- Allow read access for all users
CREATE POLICY "Allow public read access for active content" ON terms_content
    FOR SELECT USING (is_active = true);

-- Allow full access for authenticated users (more permissive for debugging)
-- You can make this more restrictive later by checking for admin role
CREATE POLICY "Allow authenticated full access" ON terms_content
    FOR ALL TO authenticated USING (true);

-- Step 5: Create/recreate indexes
CREATE INDEX IF NOT EXISTS idx_terms_content_type ON terms_content(content_type);
CREATE INDEX IF NOT EXISTS idx_terms_content_active ON terms_content(is_active);
CREATE INDEX IF NOT EXISTS idx_terms_content_effective_date ON terms_content(effective_date);

-- Step 6: Create/recreate the update trigger
CREATE OR REPLACE FUNCTION update_terms_content_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS terms_content_updated_at ON terms_content;
CREATE TRIGGER terms_content_updated_at
    BEFORE UPDATE ON terms_content
    FOR EACH ROW
    EXECUTE FUNCTION update_terms_content_updated_at();

-- Step 7: Clean up any conflicting data and insert default disclaimer
-- First, deactivate any existing disclaimer content
UPDATE terms_content 
SET is_active = false 
WHERE content_type = 'disclaimer' AND is_active = true;

-- Insert or update default disclaimer content
INSERT INTO terms_content (content_type, title_he, content_he, version, effective_date, is_active) 
VALUES (
    'disclaimer',
    'הסבר אחריות',
    'הסבר אחריות וגבולות אחריות:

1. אחריות הסטודיו:
   • הסטודיו מתחייב לספק שירותי הוראת ריקוד ברמה מקצועית
   • אנו מקפידים על תנאי בטיחות ונקיות בסטודיו
   • הציוד והמתקנים נבדקים באופן שוטף

2. אחריות התלמיד:
   • על התלמיד להקפיד על הוראות הבטיחות
   • חובת הגעה בזמן ובלבוש מתאים
   • יש להודיע מראש על בעיות רפואיות הרלוונטיות לפעילות

3. גבולות אחריות:
   • הסטודיו אינו אחראי לפציעות הנגרמות כתוצאה מאי ציות להוראות
   • אין אחריות על חפצים אישיים
   • ביטוח אישי הוא באחריות התלמיד

4. ביטול שיעורים:
   • זכות הסטודיו לבטל שיעור במקרים חירום
   • הודעה על ביטול תינתן במידת האפשר

לשאלות נוספות ניתן לפנות אלינו בכל עת.',
    '1.0',
    CURRENT_DATE,
    true
)
ON CONFLICT (content_type) WHERE is_active = true DO UPDATE SET
    title_he = EXCLUDED.title_he,
    content_he = EXCLUDED.content_he,
    version = EXCLUDED.version,
    effective_date = EXCLUDED.effective_date,
    updated_at = now();

-- Step 8: Verify the fix
SELECT 
    'terms_content table status' as check_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM terms_content WHERE content_type = 'disclaimer' AND is_active = true)
        THEN 'SUCCESS: Disclaimer content exists and is active'
        ELSE 'FAILED: No active disclaimer content found'
    END as status;

-- Final verification query
SELECT 
    id,
    content_type,
    title_he,
    LEFT(content_he, 100) || '...' as content_preview,
    version,
    is_active,
    created_at,
    updated_at
FROM terms_content 
WHERE content_type = 'disclaimer'
ORDER BY created_at DESC;