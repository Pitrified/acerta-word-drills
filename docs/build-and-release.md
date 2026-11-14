# Build and Release

## Prerequisites

- Flutter SDK, the version pinned in `.github/workflows/checks.yml`
- Android SDK (API 26+, compile and target 36)
- Java 17, a JDK with `javac`. Gradle uses `JAVA_HOME`, else the `java` on the path:
  where that is another version, set `JAVA_HOME` to the JDK 17 for the build command.
  `scripts/build-apk.sh` does it when `JAVA_HOME` is unset and `/usr/lib/jvm/java-17-openjdk-amd64` exists.

## Quick start (testable APK, no signing setup needed)

The release build falls back to debug signing when `android/key.properties` is absent.
This is enough to test on your own device:

```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or run it directly on a connected device:

```bash
flutter run --release
```

`scripts/build-apk.sh` builds the split release APKs described below, or passes its arguments to `flutter build apk`, and prints a label made of the version name from `pubspec.yaml` and the first eight characters of the commit, with `-dirty` when the tree has uncommitted changes.

## Split APKs

The default `flutter build apk` produces one fat APK carrying native libraries for every CPU architecture.
This app ships arm64-v8a (phones) and x86_64 (emulators); 32-bit armeabi-v7a is dropped until a device that needs it turns up.
Restrict the ABI set with `--target-platform` and split per architecture so a device gets only the code it runs:

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64,android-x64
```

The ABI set is controlled by the flag, not in `build.gradle.kts`: `ndk.abiFilters` conflicts with `--split-per-abi` and is overridden by the Flutter plugin's target-platform handling.
As a guard, `build.gradle.kts` also excludes `lib/armeabi-v7a/**` via `packaging` jniLibs, so a build that forgets the flag still ships no v7a libs.
The flag remains needed for split builds so Flutter does not emit an empty armeabi-v7a stub APK.

| File | Use |
|------|-----|
| `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` | 64-bit ARM, all phones since about 2016 |
| `build/app/outputs/flutter-apk/app-x86_64-release.apk` | emulators on a PC |

Flutter offsets each split's versionCode (1000 per ABI step, 2000 for arm64).
That is harmless for a direct install; installing a later build of the same ABI over it works as an update.

## Signing

### Keystore

```bash
mkdir -p ~/cred/acerta
keytool -genkey -v -keystore ~/cred/acerta/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

keytool does not create missing folders: without the `mkdir` it asks every question and then fails with `FileNotFoundException`.
It asks for a store password and the certificate's name fields.
Android checks none of the name fields: it only checks that every update is signed with the same key.
On JDK 9 and later the keystore is PKCS12, which has no separate key password, so the key password is the store password.

### key.properties

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` with the values set during keytool, the same password in both fields:

```properties
storePassword=the_password_you_chose
keyPassword=the_password_you_chose
keyAlias=upload
storeFile=/home/you/cred/acerta/upload-keystore.jks
```

The file and every `.jks` or `.keystore` are gitignored and never committed.
Without the keystore and its password, no later build installs as an update over an earlier one, so keep a copy outside the repo.

### Debug-key fallback

`android/app/build.gradle.kts` signs the release build with the `release` config when `android/key.properties` exists, and with the debug key when it does not.
The fallback is silent, so verify which key signed an APK:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

The certificate printed has to be the one from the keystore, not `CN=Android Debug`.
Android refuses an update signed with a different key, so moving between a debug-signed and a release-signed build means uninstalling first, which deletes the app's data.

## Build outputs

| Command | Output path |
|---------|-------------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Split release APKs | `build/app/outputs/flutter-apk/app-<abi>-release.apk` |

## Install on device

```bash
flutter install --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Debugging a live app on device

```bash
flutter run                      # debug mode, hot reload
flutter run --profile            # release performance, some debug info
adb logcat | grep -i "flutter\|Fatal\|AndroidRuntime"
adb logcat --pid=$(adb shell pidof com.acerta.app)
```

Look for `FATAL EXCEPTION` (unhandled crash), `FlutterError` (Dart-side exception) and `E/flutter` (engine errors).

## Permissions

The main manifest requests no permission, internet included.
The debug and profile manifests request `INTERNET`, which the Flutter tool needs for hot reload and breakpoints, so a debug APK is not a faithful check of the release permissions.
Check a release build with:

```bash
aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

## Version management

Version is in `pubspec.yaml`:

```yaml
version: 0.1.0+1
```

- `0.1.0` is the semantic version, shown to users
- `+1` is the versionCode, raised for each build that is installed over an earlier one
