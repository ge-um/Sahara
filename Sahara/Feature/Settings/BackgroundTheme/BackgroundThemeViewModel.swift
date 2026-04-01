//
//  BackgroundThemeViewModel.swift
//  Sahara
//

import Foundation
import PhotosUI
import RxCocoa
import RxSwift

final class BackgroundThemeViewModel: BaseViewModelProtocol {
    private let service: BackgroundThemeServiceProtocol
    private let disposeBag = DisposeBag()

    init(service: BackgroundThemeServiceProtocol = BackgroundThemeService.shared) {
        self.service = service
    }

    struct Input {
        let solidColorSelected: Observable<String>
        let gradientSelected: Observable<String>
        let customGradientSelected: Observable<(String, String)>
        let photoSelected: Observable<Data>
        let dotPatternToggled: Observable<Bool>
        let applyTapped: Observable<Void>
    }

    struct Output {
        let currentConfig: Driver<BackgroundConfig>
        let presetColors: Driver<[String]>
        let availableGradients: Driver<[DesignToken.Gradient]>
        let applied: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let pendingConfig = BehaviorRelay<BackgroundConfig>(value: service.currentConfig.value)

        input.solidColorSelected
            .subscribe(onNext: { hex in
                var config = pendingConfig.value
                config.theme = .solidColor(hex: hex)
                pendingConfig.accept(config)
            })
            .disposed(by: disposeBag)

        input.gradientSelected
            .subscribe(onNext: { gradientId in
                var config = pendingConfig.value
                config.theme = .gradient(gradientId: gradientId)
                pendingConfig.accept(config)
            })
            .disposed(by: disposeBag)

        input.customGradientSelected
            .subscribe(onNext: { startHex, endHex in
                var config = pendingConfig.value
                config.theme = .customGradient(startHex: startHex, endHex: endHex)
                pendingConfig.accept(config)
            })
            .disposed(by: disposeBag)

        input.photoSelected
            .subscribe(onNext: { [weak self] data in
                guard let self,
                      let fileName = try? self.service.saveBackgroundPhoto(data) else { return }
                if case .photo(let oldFileName) = pendingConfig.value.theme {
                    let isAppliedPhoto: Bool
                    if case .photo(let appliedFileName) = self.service.currentConfig.value.theme {
                        isAppliedPhoto = oldFileName == appliedFileName
                    } else {
                        isAppliedPhoto = false
                    }
                    if !isAppliedPhoto {
                        self.service.deleteBackgroundPhoto(fileName: oldFileName)
                    }
                }
                var config = pendingConfig.value
                config.theme = .photo(fileName: fileName)
                pendingConfig.accept(config)
            })
            .disposed(by: disposeBag)

        input.dotPatternToggled
            .distinctUntilChanged()
            .subscribe(onNext: { enabled in
                var config = pendingConfig.value
                config.isDotPatternEnabled = enabled
                pendingConfig.accept(config)
            })
            .disposed(by: disposeBag)

        let applied = input.applyTapped
            .withLatestFrom(pendingConfig)
            .do(onNext: { [weak self] config in
                guard let self else { return }
                let previousTheme = self.service.currentConfig.value.theme
                self.service.updateTheme(config.theme)
                self.service.updateDotPattern(enabled: config.isDotPatternEnabled)

                AnalyticsService.shared.logThemeChanged(
                    previousTheme: previousTheme.analyticsName,
                    newTheme: config.theme.analyticsName,
                    previousDetail: previousTheme.analyticsDetail,
                    newDetail: config.theme.analyticsDetail
                )
            })
            .map { _ in }
            .asDriver(onErrorDriveWith: .empty())

        let presetColors: [String] = [
            "#FFBDFF", "#F3F2FF", "#D2D1EC", "#6CA9FF", "#F9FFFF",
            "#4F7BFE", "#A6FDAB", "#FFFFC5", "#FF6B6B", "#FF009F",
            "#A6A3B4", "#FFFFFF"
        ]

        return Output(
            currentConfig: pendingConfig.asDriver(),
            presetColors: .just(presetColors),
            availableGradients: .just(DesignToken.Gradient.backgroundPresets),
            applied: applied
        )
    }
}
