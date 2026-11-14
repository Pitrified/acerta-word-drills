#!/usr/bin/env bash
# Build the APK, printing a label that names what was built: the version name
# from pubspec.yaml and the first eight characters of the commit. A tree with
# uncommitted changes gets "-dirty".
#
#   scripts/build-apk.sh                 release, split per ABI, arm64 and x86_64
#   scripts/build-apk.sh --debug         any other flutter build apk flags
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Gradle needs a JDK 17 with a compiler. Where the default java is another
# version and JAVA_HOME is unset, use the JDK 17 the distro installs.
jdk17=/usr/lib/jvm/java-17-openjdk-amd64
if [[ -z "${JAVA_HOME:-}" && -x "$jdk17/bin/javac" ]]; then
  export JAVA_HOME="$jdk17"
fi
if ! command -v flutter >/dev/null 2>&1; then
  export PATH="$HOME/flutter/bin:$PATH"
fi

version=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
commit=$(git rev-parse --short=8 HEAD)
if [[ -n "$(git status --porcelain)" ]]; then
  commit="$commit-dirty"
fi

args=("$@")
if [[ ${#args[@]} -eq 0 ]]; then
  args=(--release --split-per-abi --target-platform android-arm64,android-x64)
fi

echo "building $version+$commit"
flutter build apk "${args[@]}"
