//
//  BackgroundThemeService.swift
//  Sahara
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

protocol BackgroundThemeServiceProtocol {
    var currentConfig: BehaviorRelay<BackgroundConfig> { get }
    func updateTheme(_ theme: BackgroundTheme)
    func updateDotPattern(enabled: Bool)
    func saveBackgroundPhoto(_ imageData: Data) throws -> String
    func loadBackgroundPhoto(fileName: String) -> Data?
    func deleteBackgroundPhoto(fileName: String)
}

final class BackgroundThemeService: BackgroundThemeServiceProtocol {
    static let shared = BackgroundThemeService()

    let currentConfig: BehaviorRelay<BackgroundConfig>

    private let userDefaults: UserDefaults
    private let baseDirectory: URL
    private let fileManager = FileManager.default

    private enum Keys {
        static let backgroundConfig = "background_config"
    }

    init(userDefaults: UserDefaults = .standard, baseDirectory: URL? = nil) {
        self.userDefaults = userDefaults

        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.baseDirectory = appSupport.appendingPathComponent("BackgroundImages", isDirectory: true)
        }

        try? fileManager.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)

        let config = Self.loadConfig(from: userDefaults)
        self.currentConfig = BehaviorRelay(value: config)
    }

    func updateTheme(_ theme: BackgroundTheme) {
        let oldConfig = currentConfig.value
        if case .photo(let oldFileName) = oldConfig.theme, theme != oldConfig.theme {
            deleteBackgroundPhoto(fileName: oldFileName)
        }

        var config = oldConfig
        config.theme = theme
        saveAndEmit(config)
    }

    func updateDotPattern(enabled: Bool) {
        var config = currentConfig.value
        config.isDotPatternEnabled = enabled
        saveAndEmit(config)
    }

    func saveBackgroundPhoto(_ imageData: Data) throws -> String {
        let fileName = "background_\(UUID().uuidString.prefix(8)).jpg"
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        try imageData.write(to: fileURL, options: .atomic)
        return fileName
    }

    func loadBackgroundPhoto(fileName: String) -> Data? {
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    func deleteBackgroundPhoto(fileName: String) {
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: fileURL)
    }

    private func saveAndEmit(_ config: BackgroundConfig) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: Keys.backgroundConfig)
        }
        currentConfig.accept(config)
    }

    private static func loadConfig(from userDefaults: UserDefaults) -> BackgroundConfig {
        guard let data = userDefaults.data(forKey: Keys.backgroundConfig),
              let config = try? JSONDecoder().decode(BackgroundConfig.self, from: data) else {
            return .default
        }
        return config
    }
}
