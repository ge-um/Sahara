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
        case performance
    }

    static func logger(subsystem: Subsystem, category: Category) -> Logger {
        Logger(subsystem: subsystem.rawValue, category: category.rawValue)
    }

    static let imageMetadata = logger(subsystem: .imageProcessing, category: .metadataCapture)
    static let mediaEditor = logger(subsystem: .imageProcessing, category: .mediaEditor)
    static let cardInfo = logger(subsystem: .ui, category: .cardInfo)
    static let database = logger(subsystem: .database, category: .realmManager)
    static let performance = logger(subsystem: .ui, category: .performance)
}

extension Int? {
    var orNil: String {
        self?.description ?? "nil"
    }
}
