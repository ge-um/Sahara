.PHONY: test build help

test:
	xcodebuild test \
		-scheme Sahara \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

build:
	xcodebuild build \
		-scheme Sahara \
		-configuration Debug \
		-destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO

help:
	@echo "make test   - Run full test suite locally"
	@echo "make build  - Build without running tests"
	@echo "make help   - Show this help"
