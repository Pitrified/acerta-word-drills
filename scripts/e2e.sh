#!/usr/bin/env bash
# The slow check: the real app on an Android emulator, with the real word asset
# and real Hive boxes.
#
#   scripts/e2e.sh                 # boot if needed, run, leave the emulator up
#   scripts/e2e.sh --stop-emulator # also shut down an emulator this run booted
#
# Deliberately NOT part of scripts/check.sh: it takes minutes and needs an
# emulator (docs/getting-started.md, "The run on an emulator").
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

AVD="${AVD:-fala_api36}"
DEVICE="${DEVICE:-emulator-5554}"
OUT="${E2E_OUT:-build/e2e}"
STOP_EMULATOR=0
[ "${1:-}" = "--stop-emulator" ] && STOP_EMULATOR=1

export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
command -v flutter >/dev/null 2>&1 || export PATH="$HOME/flutter/bin:$PATH"
command -v adb >/dev/null 2>&1 || export PATH="$ANDROID_HOME/platform-tools:$PATH"
# Gradle needs a JDK 17 with javac; see docs/build-and-release.md.
jdk17=/usr/lib/jvm/java-17-openjdk-amd64
if [[ -z "${JAVA_HOME:-}" && -x "$jdk17/bin/javac" ]]; then
  export JAVA_HOME="$jdk17"
fi

mkdir -p "$OUT"
booted_here=0

cleanup() {
  if [ "$STOP_EMULATOR" = "1" ] && [ "$booted_here" = "1" ]; then
    adb -s "$DEVICE" emu kill 2>/dev/null
  fi
}
trap cleanup EXIT

booted() {
  [ "$(adb -s "$DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]
}

echo "--- emulator"
if adb devices | grep -q "^${DEVICE}[[:space:]]*device$"; then
  echo "    $DEVICE already running"
else
  echo "    booting $AVD headless"
  "$ANDROID_HOME/emulator/emulator" -avd "$AVD" \
    -no-window -gpu swiftshader_indirect -no-audio -no-boot-anim -no-snapshot-save \
    > "$OUT/emulator.log" 2>&1 &
  booted_here=1
  adb wait-for-device
  # Wait for the boot to finish, not just for adb to answer: an app installed
  # before this point fails in ways that look like app bugs.
  for _ in $(seq 1 90); do
    booted && break
    sleep 2
  done
  booted || { echo "    emulator did not finish booting; see $OUT/emulator.log"; exit 1; }
  echo "    booted"
fi

echo "--- integration test"
# The test starts from a fresh install; a run that was interrupted leaves the
# app and its data behind.
adb -s "$DEVICE" uninstall com.acerta.app >/dev/null 2>&1
flutter test integration_test/app_test.dart -d "$DEVICE" 2>&1 | tee "$OUT/test.log"
# The test's exit code, not tee's.
status=${PIPESTATUS[0]}

echo
if [ "$status" -eq 0 ]; then
  echo "e2e passed. Log: $OUT/test.log"
else
  echo "e2e FAILED (exit $status). Logs in $OUT/: test.log, emulator.log"
fi
exit "$status"
