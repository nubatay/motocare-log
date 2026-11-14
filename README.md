# MotoCare Log

A Flutter app that helps motorcycle riders track maintenance, mileage, and service reminders.

## Features
- Manage account (register, 30-day login session)
- Manage motorcycles (add, switch, edit, archive)
- Manage odometer (readings, daily distance, estimated mileage)
- Manage service records and service intervals
- Renewal dates, reminders, and expense summary

## Tech stack
- Flutter and Dart
- Supabase (PostgreSQL, Auth, row-level security)

## Development model
Incremental with a light Agile approach. See the task board for progress.

## Setup
1. Install Flutter and run `flutter pub get`.
2. Create a Supabase project and run the SQL schema.
3. Add your Supabase URL and publishable key in `lib/main.dart`.
4. Run `flutter run -d chrome`.

## Status
In development for a school project, due Dec 4.
