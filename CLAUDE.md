# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sahara is an iOS photo diary app built with UIKit that allows users to save photos with memos and view them in calendar or map views.

**Tech Stack:**
- Swift 5.0, iOS 17.0+ minimum deployment target
- UIKit (programmatic UI, NO Storyboards) with SnapKit
- RxSwift/RxCocoa for reactive programming
- RxDataSources for collection view data management
- RealmSwift for local data persistence
- Alamofire for networking
- Kingfisher for image loading

**Target Configuration:**
- Minimum iOS version: 17.0
- Supported orientations: Portrait only
- Appearance: Light mode only

## iOS Development Conventions

This project follows iOS + UIKit + RxSwift conventions.

**For detailed coding conventions, see:**
- `~/.claude/domains/ios-uikit-rxswift/CONVENTIONS.md` - Code style, memory management, UIButton, OSLog, UserDefaults, localization
- `~/.claude/domains/ios-uikit-rxswift/PATTERNS.md` - ViewModel/ViewController templates, Network Layer
- `~/.claude/domains/ios-uikit-rxswift/SWIFT-IDIOMS.md` - Collections, 방어 코드, DiffableDataSource 패턴
- `~/.claude/domains/ios-uikit-rxswift/CHECKLISTS.md` - Data Flow Tracing, Single Responsibility Principle, MVVM+RxSwift rules

**The following sections are Sahara-specific.**

## Architecture

### 폴더 컨벤션

- `Common/Service/` — DI 주입 서비스 (`*Service` suffix 기본, 역할이 명확한 이름은 예외 허용)
- `Common/Utility/` — static 유틸리티 (`*Helper` 금지)
- `Network/` — API 라우터, 네트워크 서비스, 응답 모델
- `Feature/[Name]/` — 기능별 모듈 (ViewController, ViewModel, Model, Component)

## Git Branch Strategy

feature → develop → release/hotfix → main 흐름. 상세 워크플로우: `.claude/git-strategy.md`

**핵심 규칙:**
- main/develop에 직접 커밋 금지
- 브랜치 타입: `feature/[name]` (develop 기반), `refactor/[name]` (develop 기반), `release/x.x.x` (develop 기반), `hotfix/x.x.x` (main 기반)
- release/hotfix는 반드시 main + develop 양쪽에 머지
- 비가역 원격 조작(태그 push, 강제 push) 전 사용자 확인 필수

**커밋 메시지:** 접두사 없음, 명령형, subject line only (본문 금지), Co-author/attribution 금지

## Development Commands

### Build and Run
- Open `Sahara.xcodeproj` in Xcode
- Build: `Cmd+B` in Xcode
- Run: `Cmd+R` in Xcode (or use xcodebuild from CLI)

### Dependencies
All dependencies are managed via Swift Package Manager:
- SnapKit (5.7.1+)
- RxSwift/RxCocoa (6.9.0+)
- RxDataSources (5.0.2+)
- Kingfisher (8.5.0+)
- Alamofire (5.10.2+)
- RealmSwift (20.0.3 exact)

Dependencies are resolved automatically by Xcode. If needed, resolve manually:
- Xcode → File → Packages → Resolve Package Versions

### Local Testing

로컬에서 테스트 실행:
```bash
make test    # 전체 테스트 실행
make build   # 빌드만 (테스트 없이)
```

- CI가 push 시 자동으로 테스트 실행
- 로컬에서 미리 확인하고 싶으면 `make test` 수동 실행

### Worktree 생성 후 필수 절차

`.gitignore`에 등록되어 git이 추적하지 않지만 빌드/실행에 필수인 파일 3개:
- `Sahara/GoogleService-Info.plist` — 없으면 FirebaseApp.configure()에서 런타임 크래시
- `Sahara/Secret/APIConfig.swift` — 없으면 컴파일 에러
- `Sahara/Secret/DeveloperConfig.swift` — 없으면 컴파일 에러

Worktree 생성 후 메인 저장소에서 복사:
```bash
MAIN=$(git worktree list --porcelain | head -2 | tail -1 | sed 's/worktree //')
cp "$MAIN/Sahara/GoogleService-Info.plist" Sahara/
cp -r "$MAIN/Sahara/Secret" Sahara/Secret
```

## Testing Guidelines

ViewModel과 비즈니스 로직만 테스트, ViewController는 테스트하지 않는다. 상세 패턴: `~/.claude/domains/ios-uikit-rxswift/TESTING.md`

**테스트 가치 기준:** `.claude/test-criteria.md` — 핵심 가치(편집→저장 파이프라인 + 데이터 보존) 기반의 보존/삭제 판단 기준

**핵심 규칙:**
- 모든 ViewModel은 프로토콜 기반 DI로 작성 (테스트 가능하도록)
- 테스트 이름: `test_[scenario]_[expectedBehavior]()`
- Mock은 `SaharaTests/Mocks/` 에 생성
- `make test` 로 실행
- 구현 계획 단계에서 테스트를 설계할 때: 각 테스트의 **목적**, **edge case**, **왜 필요한지**를 명시한다. "save/load/delete 테스트" 같은 한 줄 요약은 불충분하다.

**유닛 테스트에서 실제 I/O 금지:**
- 실제 이미지 생성(`UIGraphicsImageRenderer`), 파일 읽기/쓰기(`FileManager`), 네트워크 호출 금지
- 모든 외부 의존성은 프로토콜 기반 Mock으로 대체
- I/O가 필요한 테스트는 최소한의 stub 데이터(`Data([0xFF])` 등)만 사용
- CI에서 timeout 나는 테스트는 설계 결함 — 전체 테스트 스위트가 수 초 이내에 끝나야 한다

**테스트 중복 금지:**
- 새 테스트 작성 전 기존 테스트 커버리지를 검색하여 같은 알고리즘을 다른 레이어에서 중복 테스트하지 않는다
- 알고리즘 로직은 해당 컴포넌트 테스트에서 커버하고, 상위 레이어 테스트는 조합/인터페이스 수준만 검증

**테스트 가치 판단 (필수):**
- 테스트 작성 전, 이 기능의 **핵심 리스크**를 먼저 식별한다 (예: "저장 체인 변경 → 후처리가 호출되는가?")
- 각 테스트에 자문: "이 테스트가 실패하면 그건 버그인가, 의도적 변경인가?"
  - 실패 = 의도적 변경 → 구현 복제 (작성 금지)
  - 실패 = 진짜 버그 → 가치 있는 테스트

## Localization

**MANDATORY: ALL user-facing text MUST be localized in Korean, English, Japanese, and Chinese**

### Localization Files
- `Sahara/Resources/ko.lproj/Localizable.strings` (Korean - Primary)
- `Sahara/Resources/en.lproj/Localizable.strings` (English)
- `Sahara/Resources/ja.lproj/Localizable.strings` (Japanese)
- `Sahara/Resources/zh-Hans.lproj/Localizable.strings` (Simplified Chinese)

### Special Cases
- Default locale: Korean (`ko_KR`)
- Date format (Korean): "yyyy년 MM월"
- Date format (English): "MMMM yyyy"
- Date format (Japanese): "yyyy年MM月"
- Date format (Simplified Chinese): "yyyy年MM月"

## Realm Usage

- **NEVER use `try! Realm()` directly** — 반드시 Realm 서비스 레이어를 통해 DI로 접근
- 모든 ViewModel은 Realm 서비스 프로토콜을 `init` 파라미터로 주입받는다
- 앱 시작 시 `validateRealm()`으로 마이그레이션 실패를 감지
- Migration failure ≠ data corruption: the `.realm` file is intact, just can't be opened with mismatched schema
- Migration block에 `// vX.X.X → vY.Y.Y 스키마 변경 대응` 형식의 버전 주석 필수 (기존 블록 패턴 참조)

## Concurrency

- Use `DispatchQueue` for thread synchronization (serial queue `.sync` for reads, `.async` for writes)
- Do NOT use `NSLock` — error-prone and not idiomatic in modern Swift/iOS
- Never leave unused return values from `DispatchQueue.sync {}` — use `_ =` or restructure

## Code Review Scope

이번 diff에서 **새로 생성한 파일**은 "기존 코드라서 범위 밖" 면제를 적용하지 않는다.
- 새 파일의 DI 불일치, 아키텍처 위반, 미사용 프로퍼티는 즉시 수정 대상
- 기존 파일의 동일한 문제는 별도 이슈로 분리 가능

## Code Reuse

- 새 기능 구현 전 codebase에서 유사 구현을 반드시 검색
- 예: 메일 → `MFMailCompose`, 이미지 선택 → `PHPicker`, 네트워크 → `APIRouter`
- 기존 패턴이 있으면 재사용하고, 없을 때만 새로 구현
- 새 코드를 작성할 때 같은 파일 또는 같은 모듈의 기존 코드 패턴을 따른다
- 기존에 사용 중인 라이브러리/패턴 외에 새로운 것을 도입하지 않는다

## 기술 결정 시 대안 비교

기술 선택(저장 방식, 라이브러리, 아키텍처 등)을 제안할 때:
- 상위 카테고리(예: "Realm vs 디스크")뿐 아니라 **하위 선택지**(예: "FileManager vs Kingfisher 캐시 vs Core Data 외부 스토리지")도 비교한다
- 비교 테이블(장단점)을 먼저 제시한 뒤 권장안을 제시한다
- 선택지만 나열하고 "어떻게 할까요?"로 끝내지 않는다

## Disk I/O

- 같은 파일 데이터를 여러 함수에서 사용할 때: 호출자가 1번 읽고 파라미터로 전달
- 함수 내부에서 I/O 함수를 중복 호출하지 않는다

## Image Format Handling

- **Input**: JPEG, HEIC, PNG 모두 지원 (CGImageSource가 처리)
- **Disk cache output**: `CGImage.alphaInfo` 확인 → 알파 있으면 PNG, 없으면 JPEG
- Apple 기기는 하드웨어 HEIC 디코더가 있어서 HEIC 디코딩이 JPEG보다 느리지 않음

## Compiler Warnings

- 컴파일러 경고 0건 유지 — 커밋 전 반드시 확인
- Unused result: `_ =` 또는 `@discardableResult` 사용
- Deprecated API: 즉시 대체

## Code Cleanup

When the user says **"작동해"**, you MUST:

1. **Remove all debugging code:**
   - Delete all `print()` statements used for debugging
   - Remove all debug logging code
   - Remove console output statements

2. **Remove failed attempts:**
   - Delete code from approaches that didn't work
   - Remove commented-out code from previous attempts
   - Clean up any experimental code that was abandoned

3. **Remove unnecessary code:**
   - Delete unused variables, functions, and properties
   - Remove redundant code
   - Clean up any dead code paths

**This is a mandatory cleanup step before finalizing any feature.**

## TaskBoard — Automatic Task Tracking

Claude MUST automatically track work items to TaskBoard (`~/.taskboard/data/tasks.json`) during conversation.

### When to Add Tasks
Automatically run `node ~/.taskboard/cli.js add "description"` when:
- A new bug, feature request, or TODO is discussed
- The user mentions work that needs to be done (even casually)
- A problem is discovered during code review or debugging
- A follow-up task emerges from the current work

### When NOT to Add Tasks
- Trivial questions or explanations (no actionable work)
- Tasks that are being completed right now in this conversation (already doing it)
- Duplicate of something already in the board

### Task Descriptions
- Write concise, actionable descriptions in Korean
- Include enough context to understand later (e.g., "이미지 방향 버그 — 가로 사진이 뒤집혀서 표시됨")
- Don't include implementation details — just what needs to be done

### Status Management
- `node ~/.taskboard/cli.js start <id>` — when beginning work on a tracked task
- `node ~/.taskboard/cli.js pause <id> "context"` — when switching away from a task mid-work
- `node ~/.taskboard/cli.js done <id>` — when a tracked task is completed
- Check `node ~/.taskboard/cli.js ls` at session start to see pending work

### Web Dashboard
- User can run `task serve` (alias) to view kanban at `http://localhost:3456`
- User manages priorities via drag-and-drop on the board
- Claude does NOT manage priorities — only adds tasks and updates status

## GitHub Issue & PR 작성 규칙

### Issue/PR 문체 규칙

- **합니다체** 사용 ("~이다" ❌ → "~입니다" ✅)
- 사용자가 제공한 줄바꿈 구조를 임의로 변경하지 않는다
- 불필요한 줄바꿈 없이 간결하게 작성한다

### Issue vs PR 역할 분리

**Issue** — 왜(Why): 배경, 문제 정의, 작업 범위
**PR** — 무엇을 어떻게(What & How): 변경 내용, 결정 근거

Issue에 담을 것: 배경, 작업 범위, 다음 단계 참조
PR에 담을 것: 변경 내용(추가/제거/수정), 결정 근거, `Closes #N`

### Issue 1:1 PR 원칙

- **이슈 1개 = 브랜치 1개 = PR 1개**
- 다단계 작업(예: 디자인 토큰 3단계)은 이슈를 단계별로 분리
- PR에 `Closes #N`이 있으면 머지 시 이슈가 자동으로 닫힘 — 조기 닫힘 주의
- 한 이슈에 여러 PR이 필요하면 `Closes` 대신 `Related to` 사용 후 수동으로 닫기

### Issue-Branch 연결

- Issue가 있으면 반드시 `createLinkedBranch` GraphQL API로 브랜치를 생성한다 (`git checkout -b` 금지)
- `createLinkedBranch`는 브랜치 생성 + Issue Development 섹션 링크를 동시에 처리
- PR 머지 후 브랜치 auto-delete 시 linked branch 레코드도 자동 삭제됨 — 이것은 GitHub 정상 동작
- rebase는 커밋 SHA를 변경하여 링크를 깨뜨릴 수 있으므로, Issue 연결된 브랜치에서는 자동 rebase 금지

### PR 제목 형식

- **영어 명령형 동사**로 시작: Add, Fix, Update, Remove, Migrate, Optimize 등
- Issue 제목(한글)과 별개로, PR 제목은 항상 영어
- 예: Issue "카메라 촬영 사진 originalData 전달" → PR "Pass camera originalData to ImageSourceData"

### PR Body 형식

```markdown
Closes #N

## 변경 내용

**추가**
- ...

**제거**
- ...

**수정**
- ...

## 결정 근거

- **[결정 키워드]** — 이유 (리뷰어가 "왜 이렇게 했지?"라고 물을 만한 것만)
```

### PR 변경 내용 서술 수준

PR body의 "변경 내용"은 **기능 수준**으로 서술한다. 함수명·클래스명·변수명을 직접 노출하지 않는다.

- ❌ "○○ 클래스 추가, △△() 메서드 구현"
- ✅ "이미지를 디스크에 저장/로드하는 서비스 추가"
- ❌ "○○ 프로퍼티를 △△로 변경"
- ✅ "이미지 저장 방식을 Realm 내장에서 디스크 파일로 전환"

리뷰어가 구현 세부사항을 알고 싶으면 코드 diff를 본다. PR body는 "무엇이 왜 바뀌었는지"만 전달한다.

### PR/Issue 조작 사전 확인

`gh pr create`, `gh pr edit`, `gh pr close`, `gh issue create`, `gh issue close` 등
**GitHub 원격 상태를 변경하는 명령은 실행 전에 반드시 내용을 사용자에게 보여주고 확인받는다.**

- PR 생성 시: 제목 + body 전문을 먼저 제시
- PR 수정 시: 변경 전/후 diff를 제시
- 사용자가 "진행해" 또는 동의한 뒤에만 실행

## 릴리즈 노트 작성 규칙

**App Store 릴리즈 노트에서 크래시/버그를 직접 언급하지 않는다.**

- ❌ "사진 저장 시 앱이 종료되던 문제를 해결했어요" (크래시 직접 언급)
- ✅ "앱이 더욱 안정적으로 작동해요" (안정성 개선 스타일)

버그 수정만 있는 버전은 단일 항목으로 충분하다:
```
"release_note.X.X.X.1" = "앱이 더욱 안정적으로 작동해요";
```

릴리즈 노트는 **태그 push 전에 반드시 커밋되어 있어야 한다.**

## Crashlytics 크래시 대응 프로세스

Firebase MCP(`crashlytics_get_report`, `crashlytics_list_events`)로 크래시를 확인했을 때:

### hotfix 여부 판단 기준
- **즉시 hotfix**: 크래시율 > 1% 또는 특정 기기/버전에서 재현 가능한 크래시
- **다음 릴리즈 포함**: 간헐적 크래시, 재현 불가, 회피 방법 있음

### hotfix 시 표준 흐름
1. 원인 분석 → 수정 범위 확인
2. `git checkout main && git checkout -b hotfix/X.X.X`
3. 코드 수정 → 빌드 확인 → 커밋
4. 릴리즈 노트 추가 (4개 언어, 안정성 개선 스타일)
5. main 머지 + 태그 push + Xcode Cloud 트리거
6. TestFlight에서 QA → App Store 심사 제출
7. 심사 승인 후 develop 백포트 + 브랜치 삭제

### Crashlytics 분석 후 행동 원칙
스택 트레이스와 에러 코드를 확인했으면 원인 진단을 완료한 뒤 권장안을 제시한다.
"어떻게 할까요?"만 묻지 말고 분석 결과(근본 원인, 영향 범위, 수정 방법)를 함께 제시한다.

