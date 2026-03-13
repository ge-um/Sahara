//
//  KlipySticker+URL.swift
//  Sahara
//

import Foundation

extension KlipySticker {
    enum URLQualityOrder {
        case highFirst
        case lowFirst
    }

    func resolveImageURL(quality: URLQualityOrder) -> URL? {
        let qualities: [StickerQuality?]
        switch quality {
        case .highFirst:
            qualities = [file.hd, file.md, file.sm, file.xs]
        case .lowFirst:
            qualities = [file.sm, file.xs, file.md, file.hd]
        }

        for q in qualities {
            if let urlString = q?.gif?.url ?? q?.webp?.url {
                return URL(string: urlString)
            }
        }
        return nil
    }
}
