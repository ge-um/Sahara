.PHONY: test build help

CLI_DERIVED_DATA = .build

test:
	xcodebuild test \
		-scheme Sahara \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-derivedDataPath $(CLI_DERIVED_DATA) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

build:
	xcodebuild build \
		-scheme Sahara \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-derivedDataPath $(CLI_DERIVED_DATA) \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

help:
	@echo "make test   - Run full test suite locally"
	@echo "make build  - Build without running tests"
	@echo "make help   - Show this help"
