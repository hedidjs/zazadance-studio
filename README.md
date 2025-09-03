# ZaZa Dance Studio

זהו פרוייקט של אולפן הריקוד ZaZa, הכולל שתי אפליקציות Flutter:

## 📱 אפליקציות

### 1. אפליקציית המשתמשים (`user-app/`)
אפליקציית Flutter לנוחיות המשתמשים הכוללת:
- מערכת הרשמה והזדהות
- צפייה בשיעורים ותוכן לימודי
- הזמנת שירותים ומוצרים
- גלריית תמונות וסרטונים
- עדכונים ובשורות

### 2. פאנל הניהול (`admin-app/`)
אפליקציית Flutter לניהול האולפן הכוללת:
- ניהול משתמשים
- ניהול הזמנות
- ניהול תוכן (שיעורים, גלריה, עדכונים)
- סטטיסטיקות ודשבורד

## 🚀 הפריסה

- **כתובת ראשית**: [www.zazadance.com](https://www.zazadance.com) - אפליקציית המשתמשים
- **פאנל ניהול**: [www.zazadance.com/admin](https://www.zazadance.com/admin) - פאנל הניהול

## 🛠 טכנולוגיות

- **Frontend**: Flutter 3.24.0+
- **Backend**: Supabase
- **Hosting**: Netlify (עם התקנה אוטומטית של Flutter)
- **CI/CD**: GitHub Actions (אוטומטי עם Netlify)

## 🔧 התקנה ופיתוח

### דרישות מערכת
- Flutter SDK
- Dart SDK
- Android Studio / VS Code

### הרצה מקומית

```bash
# אפליקציית המשתמשים
cd user-app
flutter pub get
flutter run

# פאנל הניהול
cd admin-app
flutter pub get
flutter run
```

## 🌐 פריסה לווב

האפליקציות מותאמות לריצה בווב באמצעות Flutter Web.

```bash
# בניית הפרוייקט לווב (אוטומטי עם build.sh)
./build.sh

# או בנפרד:
cd user-app && flutter build web --release --base-href /
cd ../admin-app && flutter build web --release --base-href /admin/
```

### פריסה ב-Netlify
הפרוייקט מגיע עם קבצים סטטיים מוכנים לפריסה. Netlify פשוט יפרוס את הקבצים הקיימים ללא צורך בבניה.

## 📋 מצב הפרוייקט

✅ **הושלם**:
- בדיקת אופטימיזציה של Supabase Realtime
- העלאה לגיטהאב
- הגדרת מבנה הפרוייקט
- הגדרת פריסה אוטומטית לנטליפיי עם התקנת Flutter
- תיקון תצורת הבילד

🔄 **בתהליך**:
- תיקון בעיות Supabase Realtime (רשימה מפורטת למטה)

## 🐛 בעיות ידועות

### אפליקציית המשתמשים
- בעיות בניהול ערוצי Realtime (קבצים: groups_screen.dart, my_orders_screen.dart)
- חסר טיפול בשגיאות חיבור
- טעינה מחדש מלאה במקום עדכונים מדורגים

### פאנל הניהול
- חסר רמזור בזמן אמת לחלוטין
- בעיות ביצועים (N+1 queries)
- רענון ידני בלבד

## 🔗 קישורים חשובים

- [GitHub Repository](https://github.com/hedidjs/zazadance-studio)
- [Netlify Dashboard](https://app.netlify.com/projects/zazadance/overview)
- [Supabase Dashboard](https://supabase.com/dashboard)