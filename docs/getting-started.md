# Getting Started

## 1. Install FVM

```bash
brew tap leoafarias/fvm
brew install fvm
```

Verify:

```bash
fvm --version
```

## 2. Install Melos

```bash
dart pub global activate melos
```

Add to your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

## 3. Clone and setup

```bash
git clone https://github.com/shetty456/twilight.git
cd twilight

# Install the pinned Flutter version
fvm install

# Verify the active Flutter version
fvm flutter --version

# Resolve all workspace dependencies
fvm flutter pub get
```

## 4. Verify

```bash
# Analysis should report no issues
fvm flutter analyze

# Tests should pass
fvm flutter test
```

## 5. Run the template app

Connect a device or start an emulator/simulator.

```bash
# List connected devices
fvm flutter devices

cd apps/template
fvm flutter run
```

## Flutter version

This repo is pinned to **Flutter 3.35.6** (Dart 3.9.2). The version is in `.fvmrc` at the root. FVM reads this automatically when you run any `fvm flutter` command from inside the repo.

## Troubleshooting

**`fvm flutter` not found?** Run `fvm install` first.

**Dependencies fail to resolve?** Make sure you're running `fvm flutter pub get` from the root of the repo, not from inside an individual package.

**Android Gradle Java version warning?** This is a compatibility notice only — it does not block development builds. For release builds, configure a compatible JDK (Java 17–23) via `flutter config --jdk-dir=<path>`.
