# Golden Hour Project Explanation

## What This Project Does

Golden Hour is a highway accident response app. Its goal is to reduce the delay between an accident and the first human response.

The app is built around three ideas:

1. A driver or passenger can manually trigger an SOS using the Big Red Button
2. The system stores the accident report with GPS location and severity estimate
3. Nearby drivers and trained first-aiders can be identified and shown relevant accident information

This project is a strong academic prototype and demo system for a major project.

## Who Uses It

- Driver
- Trained first-aider
- Dispatcher

Each user signs in, completes a profile, and gets a role inside the system.

## How The Current App Works

### 1. Login and Profile Setup

- A user creates an account using Supabase authentication
- The user then completes profile setup
- The profile stores:
  - name
  - phone number
  - role
  - training status
  - vehicle number

### 2. Home Screen

After login, the app opens the dashboard:

- current location is fetched
- the user location is updated in Supabase
- nearby active accident alerts are loaded
- the user can enable crash monitoring
- the user can press the Big Red Button

### 3. Manual SOS Flow

When the user presses the Big Red Button:

- the app gets the current GPS position
- the app creates an accident detection result
- the app inserts an accident report in Supabase
- the app tries to match the nearest trained first-aider
- the app creates a driver notification entry
- the app opens the accident alert result screen

### 4. Crash Detection Flow

The app also includes accelerometer-based crash detection logic.

Current behavior:

- phone sensor values are read
- high G-force values are treated as possible crash events
- a heuristic confidence score is generated
- the app builds an alert from those values

This is enough for demo purposes, but it is not yet a medically validated crash detection engine.

### 5. Accident Result Screen

After an alert is created, the app shows:

- severity
- location
- time
- nearest responder match
- next action to return to the dashboard

## How Supabase Is Used

Supabase is the backend of this app.

### Auth

Used for:

- signup
- login
- session handling

### Database Tables

#### `profiles`

Stores all user details.

#### `accident_reports`

Stores accident alerts created by the app.

#### `driver_notifications`

Stores notifications intended for nearby drivers.

#### `emergency_call_logs`

Stores emergency call messages and related metadata.

### Database Functions

#### `nearest_first_aider`

Finds the nearest trained first-aider based on saved latitude and longitude.

#### `nearby_accident_alerts`

Returns active accidents within a selected radius, currently 500 meters.

## What Is Working Right Now

- account creation and login
- profile setup
- role-based profiles
- home dashboard
- location fetch
- manual SOS creation
- data saving to Supabase
- nearby alert loading
- first-aider matching logic
- mobile-friendly UI demo flow
- dispatcher command center
- incident lifecycle status updates
- incident timeline and dispatcher notes
- user incident history screen

## What Is Still Prototype-Level

These parts are demo-ready but not fully production-ready:

- crash detection uses heuristics, not a trained validated model
- emergency calling uses `tel:108`, not official API integration
- push notifications are not fully implemented
- browser mode is for demo; real use should be on mobile
- Realtime behavior was temporarily simplified because your Supabase project had Realtime connection issues

## What Is Needed Before “Everyone Can Use It”

If you want this app to become a real public product, these are the next major requirements:

### 1. Proper Mobile Deployment

- build and test on Android phones
- handle permissions robustly
- test battery behavior
- test background location behavior

### 2. Push Notifications

- integrate Firebase Cloud Messaging
- notify nearby drivers in real time
- notify the assigned first-aider instantly

### 3. Better Crash Detection

- train a real accident severity model
- combine accelerometer and camera evidence
- reduce false positives

### 4. Dispatcher Panel

- create a web admin panel
- show live accident map
- assign responders manually if needed
- track case status from reported to closed

Current project note:

- a first version of the dispatcher dashboard is already implemented in Flutter
- it supports viewing incidents, changing status, and writing operational notes
- the next production step would be a dedicated responsive web admin panel

### 5. Safety and Legal Readiness

- privacy policy
- consent flow
- emergency disclaimers
- secure handling of phone numbers and location

### 6. Reliability

- retry logic
- offline-safe queueing
- error recovery
- stable background sync

## Production Phase 1 Completed

The project has now entered a more product-oriented Phase 1 with:

- safer rerun-friendly Supabase schema setup
- database indexes for key lookup paths
- dispatcher case operations
- incident timeline tracking
- user incident history visibility

This makes the app much better for a serious portfolio or placement discussion, while still leaving production rollout tasks for later phases.

## Production Phase 2 Completed

The project now also includes early product-readiness features:

- backend tables for user safety preferences
- backend table for device registrations
- a user-facing Safety Settings screen
- configurable alert radius and alert behavior controls

This does not yet complete push notifications, but it prepares the system for that next production step.

## Production Phase 3 Completed

The project now includes notification-facing product features:

- notification center screen for end users
- notification read-state tracking
- automatic device-presence registration on app startup

This is still not full push delivery, but it establishes the user experience and backend structures needed before integrating Firebase Cloud Messaging or another delivery provider.

## Production Phase 4 Completed

The project now includes trusted-contact readiness:

- backend storage for emergency contacts
- user-facing contact management screen
- support for marking contacts as SOS-relevant

This makes the app feel more realistic for public use because users can maintain a personal safety network rather than using the app only as an isolated reporting tool.

## Production Phase 5 Completed

The project now includes first-run onboarding and safety setup:

- onboarding completion tracked in backend settings
- first-run preference setup flow
- safety disclaimer acceptance tracking

This makes the app more suitable for public users because they are guided through setup instead of being dropped directly into emergency controls without context.

## Production Phase 6 Completed

The project now includes a support and feedback workflow:

- backend storage for support requests
- in-app support center
- category-based reporting for bugs, safety concerns, feedback, and account issues

This is important for a public-facing product because users need a visible path to report problems and request help.

## Production Phase 7 Completed

The project now includes release-readiness surfaces:

- in-app About and Safety screen
- placeholder privacy policy
- placeholder terms of use
- Android/public release checklist

This phase improves public-product readiness because users and reviewers can now see the app’s safety framing and release documents instead of only technical features.

## Best Way To Present This In College

You should present it as:

`A working major-project prototype for a Golden Hour emergency response system`

That is honest and strong.

You should not claim:

- government-integrated live ambulance dispatch
- medically certified crash diagnosis
- nationwide public-ready deployment

Instead say:

- this project demonstrates the architecture, workflow, and first-response coordination model
- the next phase would add notifications, trained AI models, and production deployment

## Simple Real-World Flow

Here is the easiest way to explain the project to anyone:

1. A user signs in and becomes a driver or responder
2. If an accident happens, the user presses the SOS button
3. The app records the location and severity
4. The backend finds the nearest trained first-aider
5. Nearby users can see the alert
6. Emergency call flow is triggered
7. Help reaches the victim faster during the golden hour

## Final Truth

This project is already meaningful and useful as a major project.

It is not yet a finished nationwide public app, but it is a strong working prototype with real backend, real profiles, real alerts, and a clear future path.

That is exactly what a good major project should be.
