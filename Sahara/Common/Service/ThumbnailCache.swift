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

    private let cacheDirectory: URL
    private let smallCache = NSCache<NSString, UIImage>()
    private let largeCache = NSCache<NSString, UIImage>()
    private let serialQueue = DispatchQueue(label: "com.sahara.thumbnailCache.serial")
    private let loadQueue = DispatchQueue(label: "com.sahara.thumbnailCache.load", qos: .userInitiated, attributes: .concurrent)

    private var inFlightRequests: [String: [(UIImage?) -> Void]] = [:]
    private var aspectRatioCache: [ObjectId: CGFloat] = [:]
    private var cachedKeys: [ObjectId: Set<String>] = [:]

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        smallCache.countLimit = 300
        smallCache.totalCostLimit = 50 * 1024 * 1024

        largeCache.countLimit = 100
        largeCache.totalCostLimit = 100 * 1024 * 1024
    }

    // MARK: - Public Helpers

    static func bucket(_ pixelSize: CGFloat) -> Int {
        max(Int(ceil(pixelSize / 100)) * 100, 100)
    }

    static func maxPixelSize(for pointSize: CGSize, scale: CGFloat) -> CGFloat {
        max(pointSize.width, pointSize.height) * max(scale, 1)
    }

    // MARK: - Sync (memory → disk → Realm)

    func thumbnail(for cardId: ObjectId, maxPixelSize: CGFloat) -> UIImage? {
        let bucketValue = Self.bucket(maxPixelSize)
        let key = cacheKey(cardId: cardId, bucket: bucketValue)
        let cache = memoryCache(forBucket: bucketValue)

        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }

        if let (image, data) = loadFromDisk(key: key) {
            cache.setObject(image, forKey: key as NSString, cost: data.count)
            trackKey(key, for: cardId)
            return image
        }

        guard let originalData = RealmService.shared.fetchImageData(for: cardId) else {
            return nil
        }

        var effectiveDimension = CGFloat(bucketValue)
        if let imageSize = ImageDownsampler.imageSize(from: originalData),
           imageSize.width > 0, imageSize.height > 0 {
            let longSide = max(imageSize.width, imageSize.height)
            let shortSide = min(imageSize.width, imageSize.height)
            let aspectMultiplier = min(longSide / shortSide, 2.0)
            effectiveDimension = CGFloat(bucketValue) * aspectMultiplier
        }

        guard let thumbnail = ImageDownsampler.downsample(data: originalData, maxDimension: effectiveDimension) else {
            return nil
        }

        saveToDisk(thumbnail, key: key)
        cache.setObject(thumbnail, forKey: key as NSString)
        trackKey(key, for: cardId)
        return thumbnail
    }

    // MARK: - Async (background, deduplicated)

    func loadThumbnail(for cardId: ObjectId, maxPixelSize: CGFloat, completion: @escaping (UIImage?) -> Void) {
        let bucketValue = Self.bucket(maxPixelSize)
        let key = cacheKey(cardId: cardId, bucket: bucketValue)
        let cache = memoryCache(forBucket: bucketValue)

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
                self.trackKey(key, for: cardId)
                result = image
            } else if let originalData = RealmService.shared.fetchImageData(for: cardId) {
                var effectiveDimension = CGFloat(bucketValue)
                if let imageSize = ImageDownsampler.imageSize(from: originalData),
                   imageSize.width > 0, imageSize.height > 0 {
                    let longSide = max(imageSize.width, imageSize.height)
                    let shortSide = min(imageSize.width, imageSize.height)
                    let aspectMultiplier = min(longSide / shortSide, 2.0)
                    effectiveDimension = CGFloat(bucketValue) * aspectMultiplier
                }

                if let thumbnail = ImageDownsampler.downsample(data: originalData, maxDimension: effectiveDimension) {
                    self.saveToDisk(thumbnail, key: key)
                    cache.setObject(thumbnail, forKey: key as NSString)
                    self.trackKey(key, for: cardId)
                    result = thumbnail
                }
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

        let keys: Set<String> = serialQueue.sync { cachedKeys[cardId] ?? [] }
        for key in keys.sorted().reversed() {
            if let diskData = loadRawDataFromDisk(key: key),
               let imageSize = ImageDownsampler.imageSize(from: diskData),
               imageSize.width > 0 {
                let ratio = imageSize.height / imageSize.width
                serialQueue.sync { aspectRatioCache[cardId] = ratio }
                return ratio
            }
        }

        let prefix = cardId.stringValue
        if let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.deletingPathExtension().lastPathComponent.hasPrefix(prefix) {
                if let diskData = try? Data(contentsOf: file),
                   let imageSize = ImageDownsampler.imageSize(from: diskData),
                   imageSize.width > 0 {
                    let ratio = imageSize.height / imageSize.width
                    serialQueue.sync { aspectRatioCache[cardId] = ratio }
                    return ratio
                }
            }
        }

        guard let originalData = RealmService.shared.fetchImageData(for: cardId),
              let imageSize = ImageDownsampler.imageSize(from: originalData),
              imageSize.width > 0 else {
            return nil
        }

        let ratio = imageSize.height / imageSize.width
        serialQueue.sync { aspectRatioCache[cardId] = ratio }
        return ratio
    }

    // MARK: - Invalidation

    func clearAll() {
        smallCache.removeAllObjects()
        largeCache.removeAllObjects()
        serialQueue.sync {
            inFlightRequests.removeAll()
            aspectRatioCache.removeAll()
            cachedKeys.removeAll()
        }
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func invalidate(for cardId: ObjectId) {
        let keys: Set<String> = serialQueue.sync {
            cachedKeys.removeValue(forKey: cardId) ?? []
        }

        for key in keys {
            smallCache.removeObject(forKey: key as NSString)
            largeCache.removeObject(forKey: key as NSString)
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

    private func memoryCache(forBucket bucket: Int) -> NSCache<NSString, UIImage> {
        bucket <= 400 ? smallCache : largeCache
    }

    private func cacheKey(cardId: ObjectId, bucket: Int) -> String {
        "\(cardId.stringValue)_\(bucket)"
    }

    private func trackKey(_ key: String, for cardId: ObjectId) {
        serialQueue.async(flags: .barrier) {
            self.cachedKeys[cardId, default: []].insert(key)
        }
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
            if let data = image.jpegData(compressionQuality: 0.85) {
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
