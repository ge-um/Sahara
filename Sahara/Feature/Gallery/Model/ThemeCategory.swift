//
//  ThemeCategory.swift
//  Sahara
//
//  Created by Claude on 10/1/25.
//

import Foundation

enum ThemeCategory: String, CaseIterable {
    case people = "사람"
    case food = "음식"
    case animals = "동물"
    case nature = "자연"
    case buildings = "건물"
    case others = "기타"

    static func category(for labels: [String]) -> ThemeCategory {
        let lowercasedLabels = labels.map { $0.lowercased() }

        // 동물 관련 (먼저 체크)
        if lowercasedLabels.contains(where: {
            $0.contains("dog") || $0.contains("cat") || $0.contains("puppy") ||
            $0.contains("kitten") || $0.contains("pet") || $0.contains("animal") ||
            $0.contains("bird") || $0.contains("mammal") || $0.contains("canine") ||
            $0.contains("feline") || $0.contains("horse") || $0.contains("rabbit") ||
            $0.contains("fish") || $0.contains("wildlife")
        }) {
            return .animals
        }

        // 사람 관련
        if lowercasedLabels.contains(where: {
            $0.contains("person") || $0.contains("face") || $0.contains("people") ||
            $0.contains("human") || $0.contains("portrait") || $0.contains("selfie")
        }) {
            return .people
        }

        // 음식 관련
        if lowercasedLabels.contains(where: {
            $0.contains("food") || $0.contains("meal") || $0.contains("dish") ||
            $0.contains("drink") || $0.contains("fruit") || $0.contains("vegetable") ||
            $0.contains("cuisine") || $0.contains("beverage") || $0.contains("dessert") ||
            $0.contains("bread") || $0.contains("meat") || $0.contains("pizza") ||
            $0.contains("coffee") || $0.contains("tea")
        }) {
            return .food
        }

        // 자연 관련
        if lowercasedLabels.contains(where: {
            $0.contains("nature") || $0.contains("tree") || $0.contains("flower") ||
            $0.contains("sky") || $0.contains("mountain") || $0.contains("water") ||
            $0.contains("sea") || $0.contains("beach") || $0.contains("landscape") ||
            $0.contains("plant") || $0.contains("outdoor") || $0.contains("forest") ||
            $0.contains("cloud") || $0.contains("sunset") || $0.contains("sunrise")
        }) {
            return .nature
        }

        // 건물 관련
        if lowercasedLabels.contains(where: {
            $0.contains("building") || $0.contains("architecture") || $0.contains("house") ||
            $0.contains("city") || $0.contains("urban") || $0.contains("structure") ||
            $0.contains("tower") || $0.contains("bridge")
        }) {
            return .buildings
        }

        return .others
    }
}

struct ThemeGroup {
    let category: ThemeCategory
    let photoMemos: [PhotoMemo]
}