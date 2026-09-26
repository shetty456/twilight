FLUTTER := fvm flutter
DART    := fvm dart

.PHONY: help setup get analyze format test clean gen run-template build-apk build-aab

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

run-template: ## Run template against local Origin (set API_BASE_URL)
	@test -n "$(API_BASE_URL)" || (echo "Set API_BASE_URL=http://<computer-lan-ip>:8000/api/v1/" && exit 1)
	cd apps/template && $(FLUTTER) run --dart-define=APP_ENV=development --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-apk: ## Build release APK for template app
	@test -n "$(API_BASE_URL)" || (echo "Set API_BASE_URL=https://<production-host>/api/v1/" && exit 1)
	cd apps/template && $(FLUTTER) build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-apk-debug: ## Build debug APK for template app
	@test -n "$(API_BASE_URL)" || (echo "Set API_BASE_URL=http://<computer-lan-ip>:8000/api/v1/" && exit 1)
	cd apps/template && $(FLUTTER) build apk --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-aab: ## Build release AAB (Play Store) for template app
	@test -n "$(API_BASE_URL)" || (echo "Set API_BASE_URL=https://<production-host>/api/v1/" && exit 1)
	cd apps/template && $(FLUTTER) build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"

build-ipa: ## Build iOS release archive for template app
	@test -n "$(API_BASE_URL)" || (echo "Set API_BASE_URL=https://<production-host>/api/v1/" && exit 1)
	cd apps/template && $(FLUTTER) build ipa --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL="$(API_BASE_URL)"
