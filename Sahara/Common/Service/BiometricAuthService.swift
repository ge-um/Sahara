//
//  BiometricAuthService.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import LocalAuthentication
import UIKit

final class BiometricAuthService {
    static let shared = BiometricAuthService()

    private init() {}

    enum BiometricType {
        case faceID
        case touchID
        case none
    }

    var biometricType: BiometricType {
        let context = LAContext()

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }

    func checkPermission(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        DispatchQueue.main.async {
            completion(canEvaluate, error)
        }
    }

    func authenticate(feature: String = "card_view", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let nsError = error {
                if nsError.code == LAError.biometryNotAvailable.rawValue {
                    let permissionError = NSError(
                        domain: "BiometricPermissionError",
                        code: nsError.code,
                        userInfo: nsError.userInfo
                    )
                    DispatchQueue.main.async {
                        completion(false, permissionError)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }

        let reason = NSLocalizedString("biometric.reason", comment: "")

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            if success {
                AnalyticsService.shared.logBiometricAuthResult(success: true, feature: feature)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else {
                let context2 = LAContext()
                var error2: NSError?

                guard context2.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error2) else {
                    AnalyticsService.shared.logBiometricAuthResult(success: false, feature: feature)
                    DispatchQueue.main.async {
                        completion(false, error)
                    }
                    return
                }

                context2.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success2, error2 in
                    AnalyticsService.shared.logBiometricAuthResult(success: success2, feature: feature)
                    DispatchQueue.main.async {
                        completion(success2, error2)
                    }
                }
            }
        }
    }
}
