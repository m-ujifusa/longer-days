# Longer Days - iOS App Development Instructions

## Project Overview

Build a minimal iOS app called **"Longer Days"** that sends daily push notifications about daylight duration changes. The primary use case is helping users in northern latitudes (like Minnesota) track daylight gains through winter, with the psychological benefit of seeing progress since the winter solstice.

---

## Core Functionality

### Daily Notification Content

The notification should display (based on user settings):
- Minutes of daylight gained/lost compared to yesterday
- Cumulative change since the most recent solstice

**Example notifications:**
- Winter/Spring: `☀️ +2 min today | +47 min since Dec 21`
- Summer/Fall: `🌅 2 fewer minutes today | 15 min shorter since Jun 21`

### Location Handling

1. **Primary:** Request user's current location via Core Location
2. **Fallback:** Allow manual entry of city/zip code if location permission is denied
3. Store the location preference and use it for all sunrise/sunset calculations

### Sunrise/Sunset Calculations

- Use a solar calculation library or algorithm (recommended: `Solar` Swift package or implement NOAA solar calculator)
- Calculate daily sunrise, sunset, and total daylight duration
- Compare to previous day's duration stored locally
- Cache calculations to avoid redundant computation

---

## User Settings

Create a single, simple settings screen with the following options:

### 1. Notification Time
- Toggle: **"At sunrise"** (default: ON)
- If toggle is OFF: show a time picker for custom notification time
- Store preference and reschedule notifications when changed

### 2. Notification Content
- Toggle: **"Show change since solstice"** (default: ON)
- Toggle: **"Show daily change"** (default: ON)
- Validation: At least one must be enabled

### 3. Summer Mode
- Toggle: **"Pause notifications after summer solstice"** (default: OFF)
- Subtext explanation: "Resume automatically at winter solstice"
- When enabled, notifications stop after June 21 and resume after December 21

### 4. Location
- Display current location (city name or coordinates)
- Button to update location or enter manually
- If manual: accept zip code or city name, geocode to lat/long

---

## Special Cases

### Solstice Messages

Override normal notification content on solstice days:

- **Winter Solstice (Dec 21):**
  ```
  🌟 Happy Winter Solstice! The shortest day is here—every day gets brighter from now on!
  ```

- **Summer Solstice (Jun 21):**
  ```
  ☀️ Happy Summer Solstice! The longest day of the year. Enjoy the light!
  ```

### Tone Changes by Season

- **Gaining daylight (Dec 21 - Jun 21):** Positive framing, ☀️ emoji
  - Example: `☀️ +3 min today | +1 hr 12 min since Dec 21`
  
- **Losing daylight (Jun 21 - Dec 21):** Neutral/gentle framing, 🌅 emoji
  - Example: `🌅 2 fewer minutes today | 45 min shorter since Jun 21`

### Edge Cases to Handle

- App not opened for multiple days: recalculate from stored data
- Location permission revoked: prompt for manual location
- Timezone changes: recalculate notification times
- First launch: no "yesterday" data, show only current daylight duration

---

## Technical Requirements

### iOS Frameworks & Features

- **Swift & SwiftUI** for all UI
- **UNUserNotificationCenter** for local push notifications
- **Core Location** for user location
- **UserDefaults** or **SwiftData** for storing preferences and daylight data
- **Background App Refresh** to ensure reliable notification scheduling
- **CLGeocoder** for converting zip codes/city names to coordinates

### Data to Persist

- User preferences (all settings)
- Location (lat/long and display name)
- Previous day's daylight duration (for comparison)
- Current year's solstice dates (calculate once per year)

### Notification Scheduling Logic

1. After each notification fires, schedule the next day's notification
2. If "At sunrise" is enabled, calculate next sunrise and schedule for that time
3. If custom time is set, schedule for that time daily
4. Recalculate and reschedule whenever user changes settings
5. Use Background App Refresh as backup to ensure notifications stay scheduled

---

## Project Structure

```
LongerDays/
├── LongerDaysApp.swift          # App entry point
├── Models/
│   ├── DaylightData.swift       # Daylight duration, comparison results
│   ├── UserPreferences.swift    # All user settings
│   └── SolsticeInfo.swift       # Solstice dates and detection
├── Services/
│   ├── SolarCalculator.swift    # Sunrise/sunset/daylight calculations
│   ├── LocationManager.swift    # Core Location wrapper
│   └── NotificationManager.swift # Notification scheduling and content
├── Views/
│   ├── ContentView.swift        # Main settings screen
│   └── LocationPickerView.swift # Manual location entry
└── Resources/
    └── Assets.xcassets          # App icon
```

---

## Development Phases

### Phase 1: Core Solar Calculations
- [ ] Implement sunrise/sunset calculator for any latitude/longitude
- [ ] Implement daylight duration calculation (sunset - sunrise)
- [ ] Implement comparison logic (today vs yesterday, today vs solstice)
- [ ] Calculate solstice dates for any given year
- [ ] Write unit tests using known values for Minneapolis (44.9778° N, 93.2650° W)

### Phase 2: Location Services
- [ ] Implement Core Location integration with permission handling
- [ ] Build fallback manual location entry UI
- [ ] Implement geocoding (zip/city → lat/long)
- [ ] Store and retrieve location preference
- [ ] Display human-readable location name

### Phase 3: Notifications
- [ ] Set up local notification permissions request
- [ ] Build notification content formatter (handle all message variants)
- [ ] Implement sunrise-time scheduling logic
- [ ] Implement custom-time scheduling logic
- [ ] Set up Background App Refresh for reliable scheduling
- [ ] Handle notification rescheduling when settings change

### Phase 4: Settings UI
- [ ] Build SwiftUI settings screen with all toggles and pickers
- [ ] Connect settings to UserDefaults/persistence
- [ ] Ensure notifications reschedule when any relevant setting changes
- [ ] Add validation (at least one content toggle must be on)

### Phase 5: Polish & Edge Cases
- [ ] Add solstice detection and special celebration messages
- [ ] Implement summer pause feature
- [ ] Handle first-launch experience (no yesterday data)
- [ ] Handle location/timezone changes gracefully
- [ ] Design and add app icon
- [ ] Add simple launch screen
- [ ] Test all edge cases thoroughly

---

## Testing Checklist

### Calculation Accuracy
- [ ] Verify sunrise/sunset times against timeanddate.com for Minneapolis
- [ ] Verify daylight duration calculations
- [ ] Test solstice date detection for multiple years
- [ ] Test calculations for edge locations (very north/south latitudes)

### Notification Behavior
- [ ] Notifications fire at correct time (sunrise or custom)
- [ ] Content is accurate and formatted correctly
- [ ] Notifications reschedule properly after firing
- [ ] Settings changes trigger rescheduling
- [ ] Solstice messages appear on correct days

### Edge Cases
- [ ] App works after not being opened for days
- [ ] Location permission denial → manual entry flow
- [ ] Timezone changes handled correctly
- [ ] Summer pause enables/disables correctly
- [ ] First launch without yesterday's data

---

## Out of Scope (v1)

Keep the app simple. Do NOT implement:
- Widgets
- Apple Watch app
- Historical data or graphs
- Sharing features
- User accounts or cloud sync
- Multiple locations
- Weather integration

These could be considered for future versions if desired.

---

## Reference Data for Testing

**Minneapolis, MN coordinates:** 44.9778° N, 93.2650° W

**2024-2025 Reference:**
- Winter Solstice 2024: December 21
- Summer Solstice 2025: June 20
- Shortest day (Dec 21): ~8 hours 46 minutes
- Longest day (Jun 20): ~15 hours 37 minutes

---

## Notes for Claude Code

- Prioritize reliability of notifications—this is the core feature
- Keep UI minimal; users should set preferences once and forget about the app
- Use established solar calculation algorithms (NOAA) for accuracy
- Test thoroughly with Minneapolis coordinates as the reference location
- The emotional/psychological value is in the "minutes gained" messaging—make sure this feels encouraging and clear
