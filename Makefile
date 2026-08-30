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
	$(FLUTTER) test

clean: ## Clean all build artifacts
	$(FLUTTER) clean

gen: ## Run code generation (Freezed, json_serializable)
	$(DART) run build_runner build --delete-conflicting-outputs

run-template: ## Run the template app
	cd apps/template && $(FLUTTER) run

build-apk: ## Build release APK for template app
	cd apps/template && $(FLUTTER) build apk --release

build-apk-debug: ## Build debug APK for template app
	cd apps/template && $(FLUTTER) build apk --debug

build-aab: ## Build release AAB (Play Store) for template app
	cd apps/template && $(FLUTTER) build appbundle --release

build-ipa: ## Build iOS release archive for template app
	cd apps/template && $(FLUTTER) build ipa --release
