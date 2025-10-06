//
//  BiometricAuthManager.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import LocalAuthentication
import UIKit

final class BiometricAuthManager {
    static let shared = BiometricAuthManager()

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

    func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }

        let reason = NSLocalizedString("biometric.reason", comment: "")

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            if success {
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } else {
                let context2 = LAContext()
                var error2: NSError?

                guard context2.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error2) else {
                    DispatchQueue.main.async {
                        completion(false, error)
                    }
                    return
                }

                context2.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success2, error2 in
                    DispatchQueue.main.async {
                        completion(success2, error2)
                    }
                }
            }
        }
    }
}
