.PHONY: test test-ipad build screenshots screenshots-ios screenshots-mac help

CLI_DERIVED_DATA = .build

# Branch-based scheme selection
BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
ifneq (,$(filter main,$(BRANCH)))
  SCHEME ?= Sahara
else ifneq (,$(findstring release/,$(BRANCH)))
  SCHEME ?= Sahara
else ifneq (,$(findstring hotfix/,$(BRANCH)))
  SCHEME ?= Sahara
else
  SCHEME ?= SaharaDev
endif

test:
	@echo "Branch: $(BRANCH) → Scheme: $(SCHEME)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-derivedDataPath $(CLI_DERIVED_DATA) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

test-ipad:
	@echo "Branch: $(BRANCH) → Scheme: $(SCHEME) (iPad)"
	xcodebuild test \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPad (10th generation),OS=18.2' \
		-derivedDataPath $(CLI_DERIVED_DATA) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

build:
	@echo "Branch: $(BRANCH) → Scheme: $(SCHEME)"
	xcodebuild build \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-derivedDataPath $(CLI_DERIVED_DATA) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

SCREENSHOT_LANGUAGES = ko en-US ja zh-Hans
SCREENSHOT_DIR = fastlane/screenshots
MAC_CONTAINER_DIR = $(HOME)/Library/Containers/com.miya.SaharaUITests.xctrunner/Data/sahara-mac-screenshots

screenshots: screenshots-ios screenshots-mac

screenshots-ios:
	bundle exec fastlane screenshots
	@echo "📁 Organizing iPhone/iPad..."
	@for lang in $(SCREENSHOT_LANGUAGES); do \
		mkdir -p "$(SCREENSHOT_DIR)/$$lang/iphone" "$(SCREENSHOT_DIR)/$$lang/ipad"; \
		mv "$(SCREENSHOT_DIR)/$$lang"/iPhone*.png "$(SCREENSHOT_DIR)/$$lang/iphone/" 2>/dev/null || true; \
		mv "$(SCREENSHOT_DIR)/$$lang"/iPad*.png "$(SCREENSHOT_DIR)/$$lang/ipad/" 2>/dev/null || true; \
	done

screenshots-mac:
	@rm -rf "$(MAC_CONTAINER_DIR)"
	@for lang in $(SCREENSHOT_LANGUAGES); do \
		echo "📸 Mac Catalyst: $$lang"; \
		echo "$$lang" > /tmp/sahara-screenshot-lang.txt; \
		while pgrep -q SaharaUITests-Runner; do sleep 0.5; done; \
		xcodebuild -scheme Sahara -project ./Sahara.xcodeproj \
			-destination "platform=macOS,variant=Mac Catalyst" \
			-only-testing:SaharaUITests/ScreenshotTests \
			-allowProvisioningUpdates \
			FASTLANE_SNAPSHOT=YES \
			build test 2>&1 | tail -5; \
		mkdir -p "$(SCREENSHOT_DIR)/$$lang/mac"; \
		cp "$(MAC_CONTAINER_DIR)/$$lang/"*.png "$(SCREENSHOT_DIR)/$$lang/mac/" 2>/dev/null || true; \
	done

help:
	@echo "make test        - Run full test suite locally (iPhone)"
	@echo "make test-ipad   - Run full test suite locally (iPad)"
	@echo "make build       - Build without running tests"
	@echo "make screenshots     - Capture all screenshots (iPhone+iPad+Mac)"
	@echo "make screenshots-ios - iPhone + iPad only (fastlane)"
	@echo "make screenshots-mac - Mac Catalyst only (xcodebuild)"
	@echo "make help        - Show this help"
	@echo ""
	@echo "Branch: $(BRANCH) → Scheme: $(SCHEME)"
	@echo "Override: make test SCHEME=Sahara"
