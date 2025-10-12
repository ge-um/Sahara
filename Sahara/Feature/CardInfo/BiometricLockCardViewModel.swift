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
                return owner.authenticateBiometric()
            }
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

    private func authenticateBiometric() -> Observable<AuthResult> {
        return Observable.create { observer in
            let biometricType = BiometricAuthManager.shared.biometricType

            if biometricType == .none {
                observer.onNext(.noSupport)
                observer.onCompleted()
                return Disposables.create()
            }

            BiometricAuthManager.shared.authenticate(feature: "card_lock") { success, error in
                if success {
                    let biometricTypeString = biometricType == .faceID ? "faceID" : "touchID"
                    AnalyticsManager.shared.logBiometricEnabled(type: biometricTypeString)
                    observer.onNext(.success)
                } else {
                    if let error = error as NSError? {
                        if error.code == LAError.userCancel.rawValue || error.code == LAError.systemCancel.rawValue {
                            observer.onNext(.cancelled)
                        } else {
                            observer.onNext(.permissionDenied)
                        }
                    } else {
                        observer.onNext(.cancelled)
                    }
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
