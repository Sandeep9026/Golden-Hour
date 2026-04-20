# Android Release Guide

## Goal

This guide explains what is needed to move Golden Hour from development mode to an Android release candidate.

## 1. Real Device Testing

- Test login and signup on a real Android phone
- Test location permissions
- Test SOS flow
- Test settings, contacts, notifications, and support center
- Test app relaunch and session persistence

## 2. Android Configuration

After `flutter create .`, verify:

- permissions in `AndroidManifest.xml`
- package name
- app icon
- splash / launch branding

## 3. Build Commands

Example release build commands:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

```powershell
flutter build appbundle --release --dart-define=SUPABASE_URL=YOUR_PROJECT_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## 4. Signing

Before Play Store or public release:

- create a keystore
- configure signing in Android Gradle files
- store signing credentials securely

## 5. Push Notification Prep

Before public Android release:

- integrate Firebase Cloud Messaging
- register Android tokens in `device_registrations`
- test notification permissions and delivery

## 6. Release Validation

Before sharing publicly:

- confirm onboarding works for fresh users
- confirm role-based dashboards open correctly
- confirm incident creation writes to Supabase
- confirm dispatcher and history flows work
- confirm support requests save correctly

## 7. Public Release Warning

The repository is close to release-ready structurally, but a real Android public release still requires:

- signing
- push delivery
- legal review
- device QA
- monitoring
