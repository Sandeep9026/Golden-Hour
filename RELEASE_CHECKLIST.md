# Release Checklist

## Product Readiness

- Verify onboarding flow
- Verify settings screen
- Verify emergency contacts flow
- Verify support center
- Verify dispatcher workflow
- Verify incident history and notification center

## Backend Readiness

- Run latest `supabase_schema.sql`
- Confirm all tables and policies exist
- Confirm sample user roles work
- Confirm support requests, settings, and contacts save correctly

## Android Readiness

- Test on a real Android device
- Confirm location permissions
- Confirm browser/demo-only limitations are documented
- Prepare release app icon and splash assets
- Prepare signed APK/AAB pipeline

## Public Release Readiness

- Add final privacy policy
- Add final terms of use
- Add support email or contact path
- Add production monitoring and logs
- Add crash reporting
- Add notification delivery provider

## Final Validation

- Create a fresh user account
- Complete onboarding
- Report an incident
- Review incident history
- Open notifications
- Add emergency contact
- Submit a support request
- Test dispatcher account actions
