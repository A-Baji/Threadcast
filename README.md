# Threadcast

Flutter app for recording, transcribing, and sharing threaded audio conversations.

## Getting Started

1. Install Flutter and run `flutter doctor`.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Troubleshooting

### `flutter run` fails with Drift `isolateDebugLog` error

If you see an error like:

- `No named parameter with the name 'isolateDebugLog'`
- in `drift_flutter/.../native.dart`

then your dependency graph contains incompatible Drift versions (for example, `drift_flutter` newer than `drift`).

Fix:

```bash
flutter pub upgrade drift drift_dev drift_flutter
flutter pub get
flutter run
```

If the issue persists, delete `pubspec.lock` and regenerate:

```bash
rm pubspec.lock
flutter pub get
flutter run
```