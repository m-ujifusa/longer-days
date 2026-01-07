# Longer Days

An iOS app that tracks daylight duration changes and sends daily notifications about how much daylight you're gaining (or losing) throughout the year.

## Overview

Longer Days helps you stay connected to the natural rhythm of the seasons by showing you exactly how daylight hours are changing day by day. Whether you're counting down to summer or watching the days grow shorter, this app provides detailed insights into solar patterns for your location.

## Features

### Hero Dashboard
- **Cumulative daylight change** - See the total daylight gained or lost since the last solstice
- **Progress indicator** - Visual progress bar showing your journey from winter solstice to summer solstice (or vice versa)
- **Percentage tracking** - Know exactly what percentage of the way you are to the next solstice

### Velocity Widget
- **Daily change rate** - See how many minutes and seconds of daylight you're gaining or losing each day
- **Peak comparison** - View your current rate as a percentage of the peak rate (which occurs at the equinoxes)
- **Peak forecast** - Know when the maximum rate of change will occur and how much it will be

### Sun Arc Visualization
- **Apple Weather-inspired design** - Beautiful sun path arc showing the sun's journey across the sky
- **Real-time sun position** - See where the sun currently is on its daily arc
- **Sunrise/sunset markers** - Visual indicators showing when the sun crosses the horizon
- **First light/last light** - Twilight markers showing civil dawn and dusk times

### Sunrise & Sunset Card
- **Today's times** - Accurate sunrise, sunset, first light, and last light times
- **Total daylight** - See how many hours and minutes of daylight you have today
- **Daylight remaining** - Know how much daylight is left in the current day

### Countdowns
- **Days since solstice** - Track how far you've come since the last solstice
- **Days until equinox** - Count down to the next equinox
- **Days until solstice** - See how long until the next solstice

### Monthly Averages
- **Year-round overview** - See average sunrise/sunset times for each month
- **Daylight duration bars** - Visual comparison of daylight hours across the year
- **Longest day indicator** - Highlights the peak daylight duration

### Push Notifications
- **Daily reminders** - Get notified about daylight changes at your preferred time
- **Customizable content** - Choose to see daily change, cumulative change, or both
- **Sunrise scheduling** - Option to receive notifications at sunrise
- **Summer pause** - Automatically pause notifications after summer solstice

## Settings Configuration

### Location
Set your location for accurate sunrise/sunset calculations. The app uses your coordinates to compute solar positions using the NOAA solar calculation algorithm.

### Notification Time
- **Notify at sunrise** - Toggle to receive notifications exactly at sunrise
- **Custom time** - When sunrise notification is off, set your preferred notification time
- **Next notification preview** - See when your next notification is scheduled

### Notification Content
- **Show daily change** - Include how much daylight changed from yesterday (e.g., "+2m 15s")
- **Show change since solstice** - Include cumulative change since the last solstice (e.g., "+45m 30s")
- At least one option must be enabled

### Summer Mode
- **Pause after summer solstice** - When enabled, notifications will automatically pause after June 21 and resume at the winter solstice (December 21)

## Technical Details

- **Platform**: iOS 17.0+
- **Language**: Swift / SwiftUI
- **Solar Calculations**: Based on NOAA solar position algorithm
- **Location Services**: CoreLocation for coordinate-based calculations

## Privacy

- Location data is stored locally on your device
- No data is sent to external servers
- Location is only used for solar calculations

## Building the Project

1. Open `LongerDays.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (⌘R)

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
