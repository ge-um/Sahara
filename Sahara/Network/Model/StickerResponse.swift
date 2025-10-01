//
//  StickerResponse.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation

struct StickerResponse: Decodable {
    let result: Bool
    let data: StickerData
}

struct StickerData: Decodable {
    let data: [Sticker]
    let currentPage: Int?
    let perPage: Int?
    let hasNext: Bool?

    enum CodingKeys: String, CodingKey {
        case data
        case currentPage = "current_page"
        case perPage = "per_page"
        case hasNext = "has_next"
    }
}

struct Sticker: Decodable {
    let id: Int
    let slug: String
    let title: String
    let blurPreview: String?
    let file: StickerFile
    let tags: [String]?
    let type: String

    enum CodingKeys: String, CodingKey {
        case id, slug, title, file, tags, type
        case blurPreview = "blur_preview"
    }
}

struct StickerFile: Decodable {
    let hd: StickerQuality?
    let md: StickerQuality?
    let sm: StickerQuality?
    let xs: StickerQuality?
}

struct StickerQuality: Decodable {
    let gif: StickerImageInfo?
    let webp: StickerImageInfo?
    let mp4: StickerImageInfo?
}

struct StickerImageInfo: Decodable {
    let url: String
    let width: Int?
    let height: Int?
    let size: Int?
}