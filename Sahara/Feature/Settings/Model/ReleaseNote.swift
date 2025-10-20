//
//  ReleaseNote.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import Foundation

struct ReleaseNote {
    let version: String
    let date: Date
    let changes: [String]

    var dateString: String {
        return date.relativeOrAbsoluteString()
    }

    static let allVersions: [ReleaseNote] = [
        ReleaseNote(
            version: "1.4.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 17).date!,
            changes: [
                NSLocalizedString("release_note.1.4.0.1", comment: ""),
                NSLocalizedString("release_note.1.4.0.2", comment: ""),
                NSLocalizedString("release_note.1.4.0.3", comment: ""),
                NSLocalizedString("release_note.1.4.0.4", comment: ""),
                NSLocalizedString("release_note.1.4.0.5", comment: ""),
                NSLocalizedString("release_note.1.4.0.6", comment: ""),
                NSLocalizedString("release_note.1.4.0.7", comment: ""),
                NSLocalizedString("release_note.1.4.0.8", comment: ""),
                NSLocalizedString("release_note.1.4.0.9", comment: "")
            ]
        ),
        ReleaseNote(
            version: "1.3.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 13).date!,
            changes: [
                NSLocalizedString("release_note.1.3.0.1", comment: ""),
                NSLocalizedString("release_note.1.3.0.2", comment: ""),
                NSLocalizedString("release_note.1.3.0.3", comment: ""),
                NSLocalizedString("release_note.1.3.0.4", comment: ""),
                NSLocalizedString("release_note.1.3.0.5", comment: "")
            ]
        ),
        ReleaseNote(
            version: "1.2.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 10).date!,
            changes: [
                NSLocalizedString("release_note.1.2.0.1", comment: ""),
                NSLocalizedString("release_note.1.2.0.2", comment: ""),
                NSLocalizedString("release_note.1.2.0.3", comment: ""),
                NSLocalizedString("release_note.1.2.0.4", comment: "")
            ]
        ),
        ReleaseNote(
            version: "1.1.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 6).date!,
            changes: [
                NSLocalizedString("release_note.1.1.0.1", comment: ""),
                NSLocalizedString("release_note.1.1.0.2", comment: ""),
                NSLocalizedString("release_note.1.1.0.3", comment: "")
            ]
        ),
        ReleaseNote(
            version: "1.0.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 6).date!,
            changes: []
        )
    ]
}
