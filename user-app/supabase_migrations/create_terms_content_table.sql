-- Create Terms Content table for legal documents management
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

-- Create unique constraint to ensure only one active document per type
CREATE UNIQUE INDEX IF NOT EXISTS idx_terms_content_unique_active 
ON terms_content (content_type) 
WHERE is_active = true;

-- Create RLS policies
ALTER TABLE terms_content ENABLE ROW LEVEL SECURITY;

-- Allow read access for all users (both authenticated and anonymous)
-- This is important for public access to terms, privacy, and disclaimer content
CREATE POLICY IF NOT EXISTS "Allow public read access for active content" ON terms_content
    FOR SELECT USING (is_active = true);

-- Allow full access for admin users only
CREATE POLICY IF NOT EXISTS "Allow admin full access" ON terms_content
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_terms_content_type ON terms_content(content_type);
CREATE INDEX IF NOT EXISTS idx_terms_content_active ON terms_content(is_active);
CREATE INDEX IF NOT EXISTS idx_terms_content_effective_date ON terms_content(effective_date);

-- Create trigger to update updated_at timestamp
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

-- Insert default content for disclaimer (the problematic one)
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
) ON CONFLICT (content_type) WHERE is_active = true DO NOTHING;

-- Add helpful comment
COMMENT ON TABLE terms_content IS 'Legal documents content - terms of service, privacy policy, and disclaimer - managed through admin panel';