# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Sahara is an iOS photo diary app built with UIKit that allows users to save photos with memos and view them in calendar or map views.

**Tech Stack:**
- Swift 5.0, iOS 15.0+ minimum deployment target
- UIKit (programmatic UI, NO Storyboards) with SnapKit
- RxSwift/RxCocoa for reactive programming
- RxDataSources for collection view data management
- RealmSwift for local data persistence
- Alamofire for networking
- Kingfisher for image loading

**Target Configuration:**
- Minimum iOS version: 15.0
- Supported orientations: Portrait only
- Appearance: Light mode only

## Architecture

### MVVM Pattern with RxSwift

**ALWAYS use RxSwift + MVVM + Input/Output pattern for ALL ViewControllers:**

**Strict MVVM with SRP (Single Responsibility Principle):**
- **MANDATORY**: All ViewControllers MUST use MVVM with Input/Output pattern
- ViewModels follow Input/Output pattern (struct-based)
- All ViewModels implement `BaseViewModelProtocol` with `transform(input:) -> Output`
- Input: Observable streams from user interactions (viewWillAppear, button taps, etc.)
- Output: Driver/Observable streams for UI binding
- Use `DisposeBag` for memory management
- **NO Dependency Injection containers or DIP pattern**
- ViewModels are initialized directly in ViewControllers
- **ALL user interactions MUST be converted to Observables/Relays and passed through ViewModel Input**
- **ALL UI updates MUST come from ViewModel Output**

### Data Model

**PhotoMemo** (Realm Object):
- Primary data model stored in Realm
- Properties: `id` (ObjectId), `date`, `imageData`, `memo`
- Located in `Sahara/Common/Model/PhotoMemo.swift`

### Project Structure

```
Sahara/
├── Protocol/           # Shared protocols (BaseViewModel, IsIdentifiable)
├── Common/Model/       # Shared data models
├── Feature/            # Feature modules
│   ├── Gallery/        # Photo gallery with calendar/map/theme views
│   │   ├── Model/      # CalendarSection, DayItem, GalleryViewType
│   │   └── (ViewControllers & ViewModels)
│   └── Edit/           # Photo editing/memo creation
└── Secret/             # API configuration (APIRouter)
```

## Git Commit Guidelines

**IMPORTANT: Commit Message Format**
- **NEVER add Claude Code attribution or co-author information**
- Keep commit messages simple and descriptive
- Use imperative mood (e.g., "Add feature" not "Added feature")
- No emoji, no metadata, no tool attribution
- Examples:
  ```
  Add user authentication
  Fix memory leak in image loader
  Refactor network layer
  ```

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

## Coding Conventions & Patterns

### Code Comments and Documentation
- **ALWAYS add file header comments with author attribution:**
  ```swift
  //
  //  FileName.swift
  //  Sahara
  //
  //  Created by 금가경 on MM/DD/YY.
  //
  ```
- **NEVER add function comments or documentation comments**
- **NEVER use `// MARK:` comments in code**
- Code should be self-documenting through clear naming
- Only add comments for complex business logic if absolutely necessary

### Swift API Design Guidelines
Follow https://www.swift.org/documentation/api-design-guidelines/

**Key Points:**
- Clarity at the point of use is the most important goal
- Methods and functions are named as **verb phrases** (e.g., `transform`, `generateCalendar`)
- Factory methods start with `make` (e.g., `makeLabel()`)
- Boolean properties/methods read as assertions (e.g., `isEmpty`, `isHidden`)
- Protocols describing "what something is" are nouns (e.g., `Collection`)
- Protocols describing "a capability" end in `-able`, `-ible`, or `-ing` (e.g., `Equatable`)
- Avoid abbreviations; use full descriptive names
- Omit needless words

### Performance Optimization
- **Always use `final` keyword** for classes that won't be subclassed
- **Apply proper access control:**
  - Use `private` for implementation details
  - Use `fileprivate` when needed within same file
  - Default to `internal` for module-internal APIs
  - Use `public` sparingly
- Prevents dynamic dispatch overhead and enables compiler optimizations

### Memory Management
- **Avoid retain cycles:**
  - Use `[weak self]` or `[unowned self]` in closures
  - RxSwift bindings: use `withUnretained(self)` or `.bind(with: self)` (NOT `[weak self]`)
  - Never capture `self` strongly in long-lived closures
- Always use `DisposeBag` for RxSwift subscriptions
- Dispose of observers in `deinit` if needed
- **IMPORTANT**: In RxSwift chains, prefer `withUnretained(self)` over `[weak self]` for cleaner syntax

### ViewModel Implementation Pattern (MANDATORY)
**ALWAYS implement ViewModels following this pattern:**

```swift
final class SomeViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
        let buttonTapped: Observable<Void>
        let itemSelected: Observable<SomeModel>
    }

    struct Output {
        let data: Driver<[SomeData]>
        let isLoading: Driver<Bool>
        let errorMessage: Driver<String>
    }

    func transform(input: Input) -> Output {
        let dataRelay = BehaviorRelay<[SomeData]>(value: [])
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = PublishRelay<String>()

        input.viewWillAppear
            .withUnretained(self)
            .bind { owner, _ in
                isLoadingRelay.accept(true)
            }
            .disposed(by: disposeBag)

        input.buttonTapped
            .withUnretained(self)
            .bind { owner, _ in

            }
            .disposed(by: disposeBag)

        return Output(
            data: dataRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            errorMessage: errorRelay.asDriver(onErrorJustReturn: "")
        )
    }
}
```

### Network Layer Pattern
**Use Alamofire with Router pattern:**

```swift
import Alamofire

enum APIRouter: URLRequestConvertible {
    case getSomething
    case postData(parameters: Parameters)

    var baseURL: String {
        return "https://api.example.com"
    }

    var method: HTTPMethod {
        switch self {
        case .getSomething:
            return .get
        case .postData:
            return .post
        }
    }

    var path: String {
        switch self {
        case .getSomething:
            return "/endpoint"
        case .postData:
            return "/data"
        }
    }

    func asURLRequest() throws -> URLRequest {
        let url = try baseURL.asURL()
        var request = URLRequest(url: url.appendingPathComponent(path))
        request.method = method

        switch self {
        case .getSomething:
            return request
        case .postData(let parameters):
            return try JSONEncoding.default.encode(request, with: parameters)
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func request<T: Decodable>(
        router: APIRouter,
        completion: @escaping (Result<T, AFError>) -> Void
    ) {
        AF.request(router)
            .validate()
            .responseDecodable(of: T.self) { response in
                completion(response.result)
            }
    }
}
```

### Reusable Components
- Extract common UI components into separate classes
- Use protocol extensions for shared behavior
- Create base classes only when inheritance provides clear value
- Prefer composition over inheritance

### UI Construction
- **All views built programmatically with SnapKit (NO Storyboards)**
- **ALWAYS prefer SnapKit-based AutoLayout over frame-based layout**
- **NEVER use manual frame calculations unless absolutely necessary**
- ViewControllers create ViewModels directly in initializer
- Use lazy properties for views
- Apply constraints in `configureUI()` method
- Use `viewWillAppear` Observable for data loading triggers
- **ALWAYS use Relays (PublishRelay/BehaviorRelay) for custom user events**

### UIButton Configuration (MANDATORY)
**NEVER use deprecated UIButton properties. ALWAYS use UIButton.Configuration (iOS 15.0+):**

**❌ NEVER use these deprecated APIs:**
- `contentEdgeInsets` (deprecated in iOS 15.0)
- `imageEdgeInsets` (deprecated in iOS 15.0)
- `titleEdgeInsets` (deprecated in iOS 15.0)
- Direct `setTitle(_:for:)` + `titleLabel?.font` combination

**✅ ALWAYS use UIButton.Configuration:**
```swift
// ✅ Good - UIButton.Configuration
private let button: UIButton = {
    let button = UIButton()
    var config = UIButton.Configuration.filled()
    config.title = "Button Title"
    config.image = UIImage(systemName: "icon.name")
    config.imagePlacement = .leading
    config.imagePadding = 8
    config.baseBackgroundColor = .clear
    config.baseForegroundColor = .white
    config.cornerStyle = .medium
    config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

    var titleAttr = AttributeContainer()
    titleAttr.font = FontSystem.galmuriMono(size: 14)
    config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

    button.configuration = config
    button.layer.cornerRadius = 8
    button.clipsToBounds = true
    return button
}()

// ❌ Bad - Deprecated APIs
private let button: UIButton = {
    let button = UIButton()
    button.setTitle("Button Title", for: .normal)
    button.titleLabel?.font = FontSystem.galmuriMono(size: 14)
    button.setImage(UIImage(systemName: "icon.name"), for: .normal)
    button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)  // ❌
    button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 8)  // ❌
    return button
}()
```

**Key UIButton.Configuration properties:**
- `contentInsets`: Use `NSDirectionalEdgeInsets(top:leading:bottom:trailing:)` instead of `UIEdgeInsets`
- `imagePlacement`: `.leading`, `.trailing`, `.top`, `.bottom`
- `imagePadding`: Spacing between image and title
- `baseBackgroundColor`: Background color
- `baseForegroundColor`: Text and tint color
- `cornerStyle`: `.small`, `.medium`, `.large`, `.capsule`
- `attributedTitle`: Use `AttributedString` with `AttributeContainer` for custom fonts

### ViewController Structure (MANDATORY)
**ALWAYS implement ViewControllers following this pattern:**

```swift
final class SomeViewController: UIViewController {
    private let tableView = UITableView()
    private let addButton: UIButton = {
        let button = UIButton()
        button.setTitle("추가", for: .normal)
        return button
    }()

    private let viewModel: SomeViewModel
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    init(viewModel: SomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func bind() {
        let input = SomeViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            buttonTapped: addButton.rx.tap.asObservable(),
            itemSelected: tableView.rx.modelSelected(SomeModel.self).asObservable()
        )

        let output = viewModel.transform(input: input)

        output.data
            .drive(with: self) { owner, items in

            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in

            }
            .disposed(by: disposeBag)
    }

    private func configureUI() {
        view.backgroundColor = .white

        view.addSubview(tableView)
        view.addSubview(addButton)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
        }
    }
}
```

### Key Rules for MVVM + RxSwift Implementation

1. **NEVER handle business logic in ViewControllers**
   - ViewControllers only handle UI and binding
   - ALL business logic goes in ViewModel

2. **Use Relays for custom events**
   - PublishRelay for one-time events
   - BehaviorRelay for stateful values
   - Example: `private let customEventRelay = PublishRelay<SomeType>()`

3. **Memory leak prevention in RxSwift**
   - **ALWAYS use `withUnretained(self)` instead of `[weak self]` in RxSwift chains**
   - Alternative: `.bind(with: self) { owner, value in }`
   - Examples:
     ```swift
     // ✅ Good - withUnretained
     input.buttonTapped
         .withUnretained(self)
         .bind { owner, _ in
             owner.doSomething()
         }
         .disposed(by: disposeBag)

     // ✅ Good - bind(with:)
     input.buttonTapped
         .bind(with: self) { owner, _ in
             owner.doSomething()
         }
         .disposed(by: disposeBag)

     // ❌ Bad - [weak self]
     input.buttonTapped
         .bind { [weak self] _ in
             self?.doSomething()
         }
         .disposed(by: disposeBag)
     ```

4. **Use Driver for UI updates**
   - Driver guarantees main thread
   - Example: `Driver<[Item]>` for table/collection view data

5. **Separate UI construction from binding**
   - `configureUI()`: Setup views and constraints
   - `bind()`: Setup RxSwift bindings

### Realm Usage
- Initialize: `let realm = try! Realm()`
- Query photos by date range: Use `.filter("date >= %@ AND date <= %@", start, end)`
- Always observe on main thread for UI updates
- Use `@Persisted` property wrapper for Realm properties

## Localization

**MANDATORY: ALL user-facing text MUST be localized in Korean, English, and Japanese**

### Localization Rules
- **NEVER hardcode user-facing strings in code**
- **ALWAYS use `NSLocalizedString` for ALL user-facing text**
- All strings must be added to ALL three localization files:
  - `Sahara/Resources/ko.lproj/Localizable.strings` (Korean)
  - `Sahara/Resources/en.lproj/Localizable.strings` (English)
  - `Sahara/Resources/ja.lproj/Localizable.strings` (Japanese)

### Localization Key Naming Convention
Use dot notation with the following pattern:
- `feature_name.element_name` (e.g., `"gallery.empty_message"`, `"card_info.save"`)
- Group related strings by feature/screen
- Use descriptive, consistent naming

### Usage Example
```swift
// ❌ Bad - Hardcoded string
button.setTitle("저장", for: .normal)
showToast(message: "저장되었습니다.")

// ✅ Good - Localized string
button.setTitle(NSLocalizedString("common.save", comment: ""), for: .normal)
showToast(message: NSLocalizedString("card_info.save_success", comment: ""))
```

### Adding New Localized Strings
When adding new user-facing text:
1. Choose an appropriate key following the naming convention
2. Add the key-value pair to ALL three Localizable.strings files:
   - Korean (ko): Primary language
   - English (en): Required for international users
   - Japanese (ja): Required for Japanese users
3. Use `NSLocalizedString("key", comment: "")` in code

### Special Cases
- Default locale: Korean (`ko_KR`)
- Date format (Korean): "yyyy년 MM월"
- Date format (English): "MMMM yyyy"
- Date format (Japanese): "yyyy年MM月"
