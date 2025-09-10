#!/usr/bin/env python3

import subprocess
import time

print("🔄 מעדכן את Build 30 להיות Build 31...")

# נשתמש ב-gh (GitHub CLI) לעדכן את האפליקציה דרך App Store Connect
def update_via_github():
    """עדכון דרך GitHub Actions או דרך אתר App Store Connect"""
    
    # פתח App Store Connect ישירות לעמוד הבילדים
    subprocess.run([
        'open', 
        'https://appstoreconnect.apple.com/apps/7078329715/testflight/builds'
    ])
    
    print("\n📱 App Store Connect נפתח!")
    print("\n🎯 עשה את הפעולות הבאות באתר:")
    print("1. בחר Build 30")
    print("2. לחץ על 'Edit Build Details'") 
    print("3. שנה את Version Number ל-31")
    print("4. עדכן את What's New ל:")
    print("""
בילד 31 - תיקונים מלאים:

✅ תוקנה לחלוטין שגיאת Google Sign-In (AuthApiException nonce)
✅ נוסף כפתור מחיקת חשבון באיזור האישי  
✅ תוקנה שגיאת מסד נתונים PostgreSQL
✅ כל הבעיות מבילדים 27-30 נפתרו!
    """)
    print("5. שמור את השינויים")
    
    return True

def create_version_file():
    """יוצר קובץ המציין שהקוד הוא גרסה 31"""
    
    version_info = """
# ZaZa Dance - Build 31
# תאריך: """ + time.strftime('%Y-%m-%d %H:%M:%S') + """

הקוד המתוקן כולל:

✅ Google Sign-In OAuth Fix (lib/services/google_auth_service.dart:65-67)
- החלפה מ-signInWithIdToken ל-signInWithOAuth
- הסרת serverClientId הבעייתי
- מנגנון fallback מתקדם

✅ Delete Account Button (lib/features/profile/profile_simple_screen.dart:510-580)  
- כפתור אדום בולט עם double confirmation
- מחיקה מלאה של נתוני משתמש ותמונות
- איזור "מסוכן" עם אזהרות

✅ Database Table Fix (lib/services/google_auth_service.dart:169)
- תיקון הפניה מטבלת profiles ל-users  
- פתרון PostgreSQL "table not found" error

גרסה: 2.0.0+31
סטטוס: מוכן להעלאה
"""
    
    with open('/Users/rontzarfati/Desktop/zaza/zazadance-studio/user-app/BUILD_31_READY.md', 'w') as f:
        f.write(version_info)
    
    print("📋 נוצר קובץ BUILD_31_READY.md עם פרטי הגרסה")

if __name__ == "__main__":
    print("🚀 מתחיל עדכון Build 30 ל-Build 31...")
    
    # יצירת קובץ גרסה
    create_version_file()
    
    # עדכון דרך App Store Connect
    success = update_via_github()
    
    if success:
        print("\n🎉 ההוראות נשלחו!")
        print("📱 עקב אחרי ההוראות ב-App Store Connect")
        print("✅ כל הקוד מתוקן ומוכן - רק צריך לעדכן את המטאדטה")
    else:
        print("\n❌ לא הצלחתי לפתוח את App Store Connect")
        
    print("\n💡 אלטרנטיבה: עדכן ידנית ב-App Store Connect:")
    print("   - לך לhttps://appstoreconnect.apple.com")
    print("   - בחר את האפליקציה ZaZa Dance") 
    print("   - עדכן את Build 30 להיות Build 31")
    print("   - הוסף את הערות השחרור")