//
//  RemoteConfigService.swift
//  Sahara
//

import FirebaseRemoteConfig
import Foundation

extension Notification.Name {
    static let remoteConfigDidBecomeReady = Notification.Name("remoteConfigDidBecomeReady")
}

enum DefaultThemeVariant: String {
    case gradient = "gradient"
    case solidWhite = "solid_white"
}

protocol RemoteConfigServiceProtocol {
    func fetchDefaultThemeVariant() -> DefaultThemeVariant
}

final class RemoteConfigService: RemoteConfigServiceProtocol {
    static let shared = RemoteConfigService()

    private let remoteConfig: RemoteConfig
    private(set) var isReady: Bool

    private enum Keys {
        static let defaultThemeVariant = "default_theme_variant"
    }

    init(remoteConfig: RemoteConfig = RemoteConfig.remoteConfig()) {
        self.remoteConfig = remoteConfig
        self.isReady = remoteConfig.lastFetchStatus == .success

        let defaults: [String: NSObject] = [
            Keys.defaultThemeVariant: "gradient" as NSString
        ]
        remoteConfig.setDefaults(defaults)

        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        #endif
    }

    func fetchAndActivateOnce(completion: @escaping (Bool) -> Void) {
        remoteConfig.fetchAndActivate { [weak self] status, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                let success = status == .successFetchedFromRemote || status == .successUsingPreFetchedData
                if success {
                    self.isReady = true
                    NotificationCenter.default.post(name: .remoteConfigDidBecomeReady, object: nil)
                }
                completion(success)
            }
        }
    }

    func fetchDefaultThemeVariant() -> DefaultThemeVariant {
        let value = remoteConfig.configValue(forKey: Keys.defaultThemeVariant).stringValue
        return DefaultThemeVariant(rawValue: value) ?? .gradient
    }
}
