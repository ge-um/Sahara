//
//  ThumbnailCache.swift
//  Sahara
//
//  Created by 금가경 on 3/3/26.
//

import UIKit
import RealmSwift

final class ThumbnailCache {
    static let shared = ThumbnailCache()

    enum ThumbnailSize: String {
        case small
        case medium

        var maxPixelSize: CGFloat {
            switch self {
            case .small: return 200
            case .medium: return 600
            }
        }
    }

    private let cacheDirectory: URL
    private let smallCache = NSCache<NSString, UIImage>()
    private let mediumCache = NSCache<NSString, UIImage>()
    private let serialQueue = DispatchQueue(label: "com.sahara.thumbnailCache.serial")
    private let loadQueue = DispatchQueue(label: "com.sahara.thumbnailCache.load", qos: .userInitiated, attributes: .concurrent)

    private var inFlightRequests: [String: [(UIImage?) -> Void]] = [:]
    private var aspectRatioCache: [ObjectId: CGFloat] = [:]

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        smallCache.countLimit = 300
        smallCache.totalCostLimit = 50 * 1024 * 1024

        mediumCache.countLimit = 100
        mediumCache.totalCostLimit = 100 * 1024 * 1024
    }

    // MARK: - Sync (memory → disk → Realm)

    func thumbnail(for cardId: ObjectId, size: ThumbnailSize) -> UIImage? {
        let key = cacheKey(cardId: cardId, size: size)
        let cache = memoryCache(for: size)

        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        if let (image, data) = loadFromDisk(key: key) {
            cache.setObject(image, forKey: key as NSString, cost: data.count)
            return image
        }

        guard let originalData = RealmManager.shared.fetchImageData(for: cardId),
              let thumbnail = ImageDownsampler.downsample(data: originalData, maxDimension: size.maxPixelSize) else {
            return nil
        }

        saveToDisk(thumbnail, key: key)
        cache.setObject(thumbnail, forKey: key as NSString)
        return thumbnail
    }

    // MARK: - Async (background, deduplicated)

    func loadThumbnail(for cardId: ObjectId, size: ThumbnailSize, completion: @escaping (UIImage?) -> Void) {
        let key = cacheKey(cardId: cardId, size: size)
        let cache = memoryCache(for: size)

        if let cached = cache.object(forKey: key as NSString) {
            completion(cached)
            return
        }

        let shouldStart: Bool = serialQueue.sync {
            if inFlightRequests[key] != nil {
                inFlightRequests[key]?.append(completion)
                return false
            }
            inFlightRequests[key] = [completion]
            return true
        }

        guard shouldStart else { return }

        loadQueue.async { [weak self] in
            guard let self = self else { return }

            var result: UIImage?

            if let (image, data) = self.loadFromDisk(key: key) {
                cache.setObject(image, forKey: key as NSString, cost: data.count)
                result = image
            } else if let originalData = RealmManager.shared.fetchImageData(for: cardId),
                      let thumbnail = ImageDownsampler.downsample(data: originalData, maxDimension: size.maxPixelSize) {
                self.saveToDisk(thumbnail, key: key)
                cache.setObject(thumbnail, forKey: key as NSString)
                result = thumbnail
            }

            let completions: [(UIImage?) -> Void] = self.serialQueue.sync {
                self.inFlightRequests.removeValue(forKey: key) ?? []
            }

            DispatchQueue.main.async {
                completions.forEach { $0(result) }
            }
        }
    }

    // MARK: - Aspect Ratio (header only, no decode)

    func aspectRatio(for cardId: ObjectId) -> CGFloat? {
        if let cached: CGFloat = serialQueue.sync(execute: { aspectRatioCache[cardId] }) {
            return cached
        }

        for size in [ThumbnailSize.medium, .small] {
            let key = cacheKey(cardId: cardId, size: size)
            if let diskData = loadRawDataFromDisk(key: key),
               let imageSize = ImageDownsampler.imageSize(from: diskData),
               imageSize.width > 0 {
                let ratio = imageSize.height / imageSize.width
                serialQueue.sync { aspectRatioCache[cardId] = ratio }
                return ratio
            }
        }

        guard let originalData = RealmManager.shared.fetchImageData(for: cardId),
              let imageSize = ImageDownsampler.imageSize(from: originalData),
              imageSize.width > 0 else {
            return nil
        }

        let ratio = imageSize.height / imageSize.width
        serialQueue.sync { aspectRatioCache[cardId] = ratio }
        return ratio
    }

    // MARK: - Invalidation

    func invalidate(for cardId: ObjectId) {
        for size in [ThumbnailSize.small, .medium] {
            let key = cacheKey(cardId: cardId, size: size)
            memoryCache(for: size).removeObject(forKey: key as NSString)
        }

        serialQueue.sync { aspectRatioCache[cardId] = nil }

        let prefix = cardId.stringValue
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix(prefix) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    // MARK: - Private

    private func memoryCache(for size: ThumbnailSize) -> NSCache<NSString, UIImage> {
        switch size {
        case .small: return smallCache
        case .medium: return mediumCache
        }
    }

    private func cacheKey(cardId: ObjectId, size: ThumbnailSize) -> String {
        "\(cardId.stringValue)_\(size.rawValue)"
    }

    private func diskURL(for key: String, ext: String) -> URL {
        cacheDirectory.appendingPathComponent("\(key).\(ext)")
    }

    private func loadFromDisk(key: String) -> (UIImage, Data)? {
        for ext in ["jpg", "png"] {
            let url = diskURL(for: key, ext: ext)
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                return (image, data)
            }
        }
        return nil
    }

    private func loadRawDataFromDisk(key: String) -> Data? {
        for ext in ["jpg", "png"] {
            let url = diskURL(for: key, ext: ext)
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }
        return nil
    }

    private func saveToDisk(_ image: UIImage, key: String) {
        guard let cgImage = image.cgImage else { return }

        if cgImage.hasAlphaChannel {
            if let data = image.pngData() {
                try? data.write(to: diskURL(for: key, ext: "png"))
            }
        } else {
            if let data = image.jpegData(compressionQuality: 0.7) {
                try? data.write(to: diskURL(for: key, ext: "jpg"))
            }
        }
    }
}

private extension CGImage {
    var hasAlphaChannel: Bool {
        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
            return true
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        @unknown default:
            return false
        }
    }
}
