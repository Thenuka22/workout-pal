# Workout Pal

An iOS Strength Training App with Camera Rep Counting

| | |
|---|---|
| **Name** | I. T. Kannangara |
| **NIBM ID** | COBSCCOMP251P-030 |
| **Module** | iOS Application Development |

## Features

- Google sign-in (Firebase) and Face ID lock
- Profile set-up: name, gender, height and fitness level
- Exercise library from the wger API, with search and filters
- Routines, plus starter plans for each fitness level
- Workout logging with a rest timer, notes and "last time" hints
- Camera rep counter for squats and jumping jacks
- Walk and run tracker with steps and distance
- Progress charts, personal records and a training calendar
- Apple Health: reads today's steps and saves workouts
- Workout reminders, sharing and CSV export
- Dark mode, larger text and VoiceOver support

Built with SwiftUI (MVVM), Core Data, Vision, Core Motion and HealthKit.

## How to run

1. Clone the repo:
   ```
   git clone https://github.com/Thenuka22/workout-pal.git
   ```
2. Open `Workout Pal.xcodeproj` in Xcode on a Mac.
3. Wait for Xcode to download the Swift packages (Firebase and Google Sign-In).
4. Choose the **Workout Pal** scheme and an iPhone running iOS 17 or later.
5. Press **⌘R** to run the app, or **⌘U** to run the tests.

To run on a real iPhone, select your team under **Signing & Capabilities**. The camera counter, step tracking, Face ID and Apple Health need a real device.
