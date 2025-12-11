# Hearth - App

## Getting Started
Things you'll need:
- Minimum:
  - [Flutter](https://docs.flutter.dev/get-started/install) (v3.27.x^)
    - Very least, install web tooling. Can install Android/iOS if you would like.
- Android Development:
  - [Android Studio](https://developer.android.com/studio) (Ladybug^)
    - This is needed to install Android SDK and related tools, such as the emulator.
  - [Android Flutter Installation Instructions](https://docs.flutter.dev/get-started/install/windows/mobile)
- iOS Development:
  - [Xcode](https://xcodereleases.com/) (16^)
  - [iOS Flutter Installation Instructions](https://docs.flutter.dev/get-started/install/macos/mobile-ios)

Recommended:
- [VSCode](https://code.visualstudio.com/download)
- [Flutter - VSCode Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
  - This can also be used to install Flutter, I believe.

Make sure to follow installation guide on Flutter's website for each specific tooling.

Use the following command to verify all tooling you want is installed and working correctly:

```bash
flutter doctor
```

## Running
To run the app, you can open a terminal into the `/app/` directory and use the following command:

```bash
flutter run
```

If you already have an emulator open, it will attach to it, otherwise it will show you the available
options for web. To start an emulator, you can easily do so inside of VSCode or by using the following
commands:

```bash
# See all emulators
flutter emulators

# Launch a specific one via it's id. Only seen android emulators work with this one.
flutter emulators --launch <emulator id>

# Launch iOS simulator.
open -a Simulator.app
```

## Building
To see all build targets, run the following:

```bash
flutter help build
```

Once you've found your desired build target, use the build command:

```bash
flutter build <target>
```

Here are the likely build targets we'll be using:
| Platform    | Target Command      |
| ----------- | ------------------- |
| Web         | `flutter build web` |
| Android App | `flutter build apk` |
| iOS App     | `flutter build ios` |

#### Note
The web build output is pretty big so we might want to take a look at adding a bundler
before deploying it.

## Testing
Some unit tests require the API, so make sure that is running on port `3456` beforehand:

```bash
# Start API
cd api
go run ./core/

# Run flutter unit tests
cd ../app
flutter test
```

## Flutter Resources

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
