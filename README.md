# DevCamp To-Do List

A Flutter task manager for Android with local SQLite persistence. Tasks can be created, edited, completed, and deleted, and the interface supports light and dark themes.

## Features

- Create a task with a required title, optional description, and optional due date.
- View tasks in ascending due-date order.
- Edit a task's title, description, and due date without changing its completion state or creation date.
- Mark tasks complete or incomplete by tapping the status icon. Completed tasks use a green check and a strikethrough title.
- Delete a task after confirming the action.
- Persist all tasks locally with SQLite so the list survives app restarts.
- Switch between light and dark themes from the AppBar.
- Validate empty titles and format dates with `intl`.

## Tech Stack

- Flutter and Dart
- `sqflite` for local SQLite storage
- `path` for resolving the database location
- `intl` for date formatting

## Getting Started

### Prerequisites

- Flutter SDK with Dart 3.13.4 or newer
- Android Studio with the Android SDK installed, or a configured Flutter development environment
- An Android emulator or a physical Android device with USB debugging enabled

### Install and Run

```bash
git clone https://github.com/your-username/devcamp_dart.git
cd devcamp_dart
flutter pub get
flutter run
```

If more than one device is available, list them and select one:

```bash
flutter devices
flutter run -d <device-id>
```

### Build a Release APK

```bash
flutter build apk --release
```

The APK is written to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Static Analysis

```bash
flutter analyze
```

## How to Use

1. On the **Add Task** screen, enter a title. A description and due date are optional.
2. Tap **Add Task**. The form clears so another task can be entered.
3. Tap **Show Current Tasks** to open the task list.
4. Tap the circle beside a task to mark it complete. Tap the green check to mark it incomplete again.
5. Tap **Edit Tasks**, then the pencil beside a task. Change the title, description, or due date and tap **Save Changes**.
6. Tap the trash icon and confirm to delete a task.
7. Use the sun or moon icon in the AppBar to switch between light and dark mode.
8. Tap **Back** to return to the Add Task screen.

## Demo Walkthrough

For the assignment demonstration:

1. Create at least three tasks.
2. Edit one task and confirm the updated values appear in the list.
3. Mark one task complete.
4. Delete one task.
5. Close and reopen the app to show that the remaining tasks were saved.
6. Switch between light and dark mode.

## Data Storage

Tasks are stored in a SQLite database named `tasks_database.db` in the app's databases directory, resolved with `getDatabasesPath()`.

The `tasks` table has the following columns:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER | Primary key, auto-increment |
| `title` | TEXT | Required |
| `description` | TEXT | Optional |
| `dueDate` | DATETIME | Optional, stored as an ISO-8601 string |
| `isCompleted` | INTEGER | `0` for incomplete, `1` for complete |
| `createdAt` | DATETIME | Stored as an ISO-8601 string |

Tasks are returned with `ORDER BY dueDate ASC`. Data is kept between launches and is removed when the app is uninstalled or its storage is cleared.

## Project Structure

```text
lib/
  main.dart            Task model, database helper, screens, and themes
android/               Android host project
pubspec.yaml           Flutter dependencies and project metadata
```

`lib/main.dart` contains:

- `Task` — task data model and SQLite mapping
- `DatabaseHelper` — database creation, queries, insert, update, completion toggle, and delete
- `MyApp` — light/dark theme state and app configuration
- `AddTaskScreen` — add and edit form
- `TaskListScreen` — task list, completion, edit mode, and deletion

## Planned Improvements

- Categories or priorities for tasks
- Search and filters for completed and pending tasks
- Persisting the selected theme across restarts
- A progress summary for the task list
