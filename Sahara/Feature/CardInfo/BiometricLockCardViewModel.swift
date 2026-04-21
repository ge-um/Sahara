//
//  BiometricLockCardViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import Foundation
import LocalAuthentication
import RxCocoa
import RxSwift

final class BiometricLockCardViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let initialIsLocked: Bool

    init(initialIsLocked: Bool = false) {
        self.initialIsLocked = initialIsLocked
    }

    struct Input {
        let switchToggled: Observable<Bool>
    }

    struct Output {
        let switchValue: Driver<Bool>
        let presentPermissionAlert: Driver<Void>
        let showNoSupportToast: Driver<String>
        let isLocked: Driver<Bool>
    }

    func transform(input: Input) -> Output {
        let switchValueRelay = BehaviorRelay<Bool>(value: initialIsLocked)
        let presentPermissionAlertRelay = PublishRelay<Void>()
        let showNoSupportToastRelay = PublishRelay<String>()

        input.switchToggled
            .skip(1)
            .filter { $0 == true }
            .withUnretained(self)
            .flatMap { owner, _ -> Observable<AuthResult> in
                return owner.checkBiometricPermission()
            }
            .do(onNext: { result in
                if case .success = result {
                    let biometricType = BiometricAuthService.shared.biometricType
                    let biometricTypeString = biometricType == .faceID ? "faceID" : "touchID"
                    AnalyticsService.shared.logBiometricEnabled(type: biometricTypeString)
                }
            })
            .bind(with: self) { owner, result in
                switch result {
                case .success:
                    switchValueRelay.accept(true)
                case .noSupport:
                    switchValueRelay.accept(false)
                    showNoSupportToastRelay.accept(NSLocalizedString("biometric.no_biometric", comment: ""))
                case .permissionDenied:
                    switchValueRelay.accept(false)
                    presentPermissionAlertRelay.accept(())
                case .cancelled:
                    switchValueRelay.accept(false)
                }
            }
            .disposed(by: disposeBag)

        return Output(
            switchValue: switchValueRelay.asDriver(),
            presentPermissionAlert: presentPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            showNoSupportToast: showNoSupportToastRelay.asDriver(onErrorJustReturn: ""),
            isLocked: switchValueRelay.asDriver()
        )
    }

    private enum AuthResult {
        case success
        case noSupport
        case permissionDenied
        case cancelled
    }

    private func checkBiometricPermission() -> Observable<AuthResult> {
        return Observable.create { observer in
            let biometricType = BiometricAuthService.shared.biometricType

            if biometricType == .none {
                observer.onNext(.noSupport)
                observer.onCompleted()
                return Disposables.create()
            }

            observer.onNext(.success)
            observer.onCompleted()

            return Disposables.create()
        }
    }
}
