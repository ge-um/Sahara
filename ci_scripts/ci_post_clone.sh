#!/bin/sh

# Xcode Cloud - Post Clone Script
# Secret 파일들을 환경변수에서 생성

set -e

echo "Creating secret files..."

# GoogleService-Info.plist
if [ -n "$GOOGLE_SERVICE_INFO_PLIST" ]; then
    echo "$GOOGLE_SERVICE_INFO_PLIST" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/Sahara/GoogleService-Info.plist"
    echo "GoogleService-Info.plist created"
else
    echo "Warning: GOOGLE_SERVICE_INFO_PLIST not set"
fi

# Secret 폴더 생성
mkdir -p "$CI_PRIMARY_REPOSITORY_PATH/Sahara/Secret"

# APIConfig.swift
if [ -n "$API_CONFIG_SWIFT" ]; then
    echo "$API_CONFIG_SWIFT" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/Sahara/Secret/APIConfig.swift"
    echo "APIConfig.swift created"
else
    echo "Warning: API_CONFIG_SWIFT not set"
fi

# DeveloperConfig.swift
if [ -n "$DEVELOPER_CONFIG_SWIFT" ]; then
    echo "$DEVELOPER_CONFIG_SWIFT" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/Sahara/Secret/DeveloperConfig.swift"
    echo "DeveloperConfig.swift created"
else
    echo "Warning: DEVELOPER_CONFIG_SWIFT not set"
fi

echo "Secret files setup complete"
