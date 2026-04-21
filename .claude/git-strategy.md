# Sahara Git Branch Strategy

Feature Branch + Develop Integration (Solo Development)

## Branch Structure

| 브랜치 | 용도 | 기반 | 머지 대상 |
|--------|------|------|-----------|
| `main` | 프로덕션 (App Store 릴리즈만) | - | - |
| `develop` | 완성된 피처 통합 | - | - |
| `feature/[name]` | 신규 기능 개발 | develop | develop (PR) |
| `refactor/[name]` | 구조 개선, 리팩토링 | develop | develop (PR) |
| `release/x.x.x` | 출시 준비 | develop | main + develop |
| `hotfix/x.x.x` | 긴급 버그 수정 (피처 없이) | main | main + develop |

**NEVER commit directly to main or develop**

## When to Use Which Branch

| 시나리오 | 브랜치 타입 |
|----------|-------------|
| 새 기능 작업 | `feature/[name]` |
| 구조 개선, 리팩토링 | `refactor/[name]` |
| 일반 릴리즈 (완성 피처 포함) | `release/x.x.x` from develop |
| 버그 + 완성 피처 함께 배포 | `release/x.x.x` from develop |
| 버그만 (피처 제외) 긴급 배포 | `hotfix/x.x.x` from main |

## Feature Development

```bash
git checkout develop && git pull origin develop
git checkout -b feature/edit-photos
# ... 작업 ...
git push -u origin feature/edit-photos
gh pr create --base develop --title "Add photo editing screen"
# PR 머지 후
git checkout develop && git pull origin develop
git branch -d feature/edit-photos
```

## Release (Normal)

```bash
git checkout develop && git pull origin develop
git checkout -b release/1.1.0
# Xcode에서 CFBundleShortVersionString 업데이트
git commit -m "Bump version to 1.1.0"
git checkout main && git merge release/1.1.0
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main v1.1.0
git checkout develop && git merge main && git push origin develop
git branch -d release/1.1.0
```

## Hotfix (Bug Only)

```bash
git checkout main
git checkout -b hotfix/1.0.1
# 버그 수정
git commit -m "Critical crash on launch"
git checkout main && git merge hotfix/1.0.1
git tag -a v1.0.1 -m "Hotfix version 1.0.1"
git push origin main v1.0.1
git checkout develop && git merge hotfix/1.0.1 && git push origin develop
git branch -d hotfix/1.0.1
```

## Release Branch QA Rules

- release 브랜치에 새 커밋 추가 시: push → TestFlight → 수동 QA 완료 후에만 `/release-appstore` 실행
- 비가역 원격 조작(태그 push, 브랜치 삭제) 전 반드시 사용자 확인
- 릴리즈 순서: `commit → push → TestFlight → 수동 QA → /release-appstore → /finish-release`

## Version Numbering

**Semantic Versioning: MAJOR.MINOR.PATCH**
- MAJOR: 호환성 깨지는 변경 (1.0.0 → 2.0.0)
- MINOR: 새 기능 (1.0.0 → 1.1.0)
- PATCH: 버그 수정 (1.0.0 → 1.0.1)

Build Number: Xcode Cloud가 자동 증가 (수동 관리 불필요)

## Commit Message Format

- 접두사 없음 (Add:, Fix: 등 사용 금지)
- 명령형 (e.g., "Add feature" not "Added feature")
- Co-author/attribution 절대 금지
- 이모지, 메타데이터 없음
