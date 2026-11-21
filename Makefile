FLUTTER := fvm flutter
DART    := fvm dart
API_BASE_URL ?= https://origin-production-5ab8.up.railway.app/api/v1/
APP ?= template
APP_DIR := apps/$(APP)
AVAILABLE_APPS := $(patsubst apps/%/pubspec.yaml,%,$(wildcard apps/*/pubspec.yaml))

.PHONY: help setup get analyze format format-check test clean gen check-app run run-template build-apk build-apk-debug build-aab build-ipa

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install FVM SDK and resolve dependencies
	fvm install
	$(FLUTTER) pub get

get: ## Resolve workspace dependencies
	$(FLUTTER) pub get

analyze: ## Run static analysis
	$(FLUTTER) analyze

format: ## Format all Dart code in-place
	$(DART) format .

format-check: ## Check formatting without modifying files
	$(DART) format . --set-exit-if-changed

test: ## Run all tests
	bash scripts/test_workspace.sh

clean: ## Clean all build artifacts
	$(FLUTTER) clean

gen: ## Run code generation (Freezed, json_serializable)
	$(DART) run build_runner build --delete-conflicting-outputs

check-app:
	@test -f "$(APP_DIR)/pubspec.yaml" || { echo "Unknown app '$(APP)'. Available: $(AVAILABLE_APPS)" >&2; exit 1; }

run: check-app ## Run selected app against the testing backend (APP=template by default)
	cd "$(APP_DIR)" && $(FLUTTER) run --dart-define=APP_ENV=development --dart-define=API_BASE_URL="$(API_BASE_URL)"

run-template: ## Run template app (alias for make run APP=template)
	$(MAKE) run APP=template API_BASE_URL="$(API_BASE_URL)"

build-apk: check-app ## Build release APK for selected app
	cd "$(APP_DIR)" && $(FLUTTER) build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-apk-debug: check-app ## Build debug APK for selected app
	cd "$(APP_DIR)" && $(FLUTTER) build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-aab: check-app ## Build release AAB (Play Store) for selected app
	cd "$(APP_DIR)" && $(FLUTTER) build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-ipa: check-app ## Build iOS release archive for selected app
	cd "$(APP_DIR)" && $(FLUTTER) build ipa --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"
