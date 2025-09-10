# App Review Response - ZaZa Dance Studio

## Response to App Review Team

**Date:** September 10, 2025  
**App:** ZaZa Dance Studio  
**Version:** 3.0.0+1  
**Submission ID:** d3a3ff13-ce00-4012-bb96-fcd32a03f4b0

---

Dear App Review Team,

Thank you for reviewing our app and providing detailed feedback. I would like to address both issues raised in your review:

## 1. Account Deletion Functionality (Guideline 5.1.1)

**Status: ✅ RESOLVED**

The app **already includes comprehensive account deletion functionality**. Users can access this feature by:

1. **Opening the app** and signing in
2. **Navigating to the Profile screen** (bottom navigation bar - rightmost icon)
3. **Scrolling down** to the "Account Management" section (ניהול חשבון)
4. **Tapping the "Remove Account" button** (הסר חשבון)
5. **Confirming deletion** through a double-confirmation dialog

### Account Deletion Features:
- ✅ **Complete account deletion** (not just deactivation)
- ✅ **Immediate data removal** from all database tables
- ✅ **File cleanup** - removes profile images and user-uploaded content
- ✅ **Authentication cleanup** - removes both Google and local authentication
- ✅ **User confirmation** - requires double confirmation to prevent accidental deletion
- ✅ **Automatic logout** - logs user out and redirects to login screen after deletion

The account deletion functionality is implemented in:
- **File:** `lib/features/profile/profile_simple_screen.dart` (lines 526-594)
- **Service:** `lib/services/google_auth_service.dart` (deleteUserAccount method)
- **Database function:** `delete_user_account` (handles complete data cleanup)

## 2. Support URL (Guideline 1.5)

**Status: ✅ RESOLVED**

The support URL **https://zazadance.com/support** is now fully functional and includes:

### Support Page Features:
- ✅ **Comprehensive FAQ section** covering:
  - Login and authentication issues
  - Account deletion procedures  
  - App loading problems
  - Profile management
  - General troubleshooting

- ✅ **Contact form** with fields for:
  - Full name and email
  - Issue type categorization
  - Detailed message description

- ✅ **Direct contact information:**
  - Email: sharon.art6263@gmail.com
  - Phone: 0527274321
  - Support hours: Monday-Friday, 9:00-17:00
  - Response time: Within 24 hours

- ✅ **Mobile-responsive design** with Hebrew language support

## 3. Additional Improvements Made

### Privacy Policy & Terms Updates
We have also created comprehensive legal documentation:

- ✅ **Privacy Policy:** https://zazadance.com/privacy
- ✅ **Terms of Service:** https://zazadance.com/terms  
- ✅ **Liability Disclaimer:** https://zazadance.com/disclaimer

These pages feature:
- **Dynamic content** - automatically updates from our database
- **Full accessibility support** - screen reader compatible, high contrast, large fonts
- **GDPR compliance** - comprehensive data protection information
- **Hebrew language support** - RTL layout and proper Hebrew typography

### App Privacy Information
We have updated the `NSUserTrackingUsageDescription` to provide clearer information about data collection:

*"אנו אוספים מידע מוגבל כדי לשפר את חוויית השימוש שלך באפליקציה. המידע משמש להתחברות עם Google, שמירת העדפות אישיות ושיפור השירות. המידע לא נמכר לצדדים שלישיים."*

*Translation: "We collect limited information to improve your app experience. The information is used for Google authentication, saving personal preferences, and service improvement. Information is not sold to third parties."*

## 4. App Privacy Data Types

For the App Store Connect privacy section, our app collects:

### Data Types We Collect:
- **Identifiers:** Email address, User ID (for account management)
- **Usage Data:** App interactions, feature usage (for service improvement)
- **Diagnostics:** Crash reports, performance data (for bug fixes)

### Data We DON'T Collect:
- ❌ Location data (beyond general region)
- ❌ Financial information (payments handled by platform)
- ❌ Sensitive personal data
- ❌ Third-party tracking for advertising

## 5. Testing Instructions

To verify these features:

### Account Deletion Test:
1. Download the app from TestFlight or App Store
2. Sign in with any Google account
3. Navigate: Profile → Scroll down → "Account Management" section → "Remove Account"
4. Confirm deletion in both dialog boxes
5. Verify user is logged out and redirected to login screen

### Support URL Test:
1. Visit: https://zazadance.com/support
2. Verify page loads with FAQ and contact form
3. Test contact form functionality

## 6. Conclusion

Both issues have been resolved:
- ✅ **Account deletion** - Fully functional in Profile screen
- ✅ **Support URL** - Active and comprehensive

The app is now ready for approval. All features comply with App Store guidelines and provide users with complete control over their data and account management.

Thank you for your thorough review process. Please let us know if you need any additional information or clarification.

Best regards,
ZaZa Dance Development Team

---

**Contact Information:**
- Email: sharon.art6263@gmail.com
- Phone: +972-52-727-4321
- Support: https://zazadance.com/support