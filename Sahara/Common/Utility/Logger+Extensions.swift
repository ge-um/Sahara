//
//  Logger+Extensions.swift
//  Sahara
//
//  Created by 금가경 on 12/17/25.
//

import OSLog

extension Logger {
    enum Subsystem: String {
        case imageProcessing
        case ui
        case database
    }

    enum Category: String {
        case metadataCapture
        case mediaEditor
        case cardInfo
        case realmManager
    }

    static func logger(subsystem: Subsystem, category: Category) -> Logger {
        Logger(subsystem: subsystem.rawValue, category: category.rawValue)
    }

    static let imageMetadata = logger(subsystem: .imageProcessing, category: .metadataCapture)
    static let mediaEditor = logger(subsystem: .imageProcessing, category: .mediaEditor)
    static let cardInfo = logger(subsystem: .ui, category: .cardInfo)
    static let database = logger(subsystem: .database, category: .realmManager)
}

extension Int? {
    var orNil: String {
        self?.description ?? "nil"
    }
}

extension CropMetadata {
    func formattedCoordinates() -> String {
        "x: \(String(format: "%.4f", self.x)), y: \(String(format: "%.4f", self.y)), width: \(String(format: "%.4f", self.width)), height: \(String(format: "%.4f", self.height))"
    }
}

extension CropMetadata? {
    var presenceLog: String {
        self != nil ? "present" : "nil"
    }
}
