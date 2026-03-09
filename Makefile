.PHONY: test test-ipad build help

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

help:
	@echo "make test      - Run full test suite locally (iPhone)"
	@echo "make test-ipad - Run full test suite locally (iPad)"
	@echo "make build     - Build without running tests"
	@echo "make help      - Show this help"
	@echo ""
	@echo "Branch: $(BRANCH) → Scheme: $(SCHEME)"
	@echo "Override: make test SCHEME=Sahara"
