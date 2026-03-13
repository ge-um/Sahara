//
//  CardPostProcessor.swift
//  Sahara
//
//  Created by 금가경 on 3/13/26.
//

import Foundation
import OSLog
import RealmSwift
import UIKit
import Vision

protocol CardPostProcessorProtocol {
    func process(cardId: ObjectId, imageData: Data)
    func processUntaggedCards()
}

final class CardPostProcessor: CardPostProcessorProtocol {
    static let shared = CardPostProcessor()

    private let realmConfiguration: Realm.Configuration
    private let queue = DispatchQueue(label: "com.sahara.postProcessor", qos: .utility)

    init(realmConfiguration: Realm.Configuration? = nil) {
        self.realmConfiguration = realmConfiguration ?? RealmManager.shared.createConfiguration()
    }

    func process(cardId: ObjectId, imageData: Data) {
        queue.async { [weak self] in
            self?.performProcess(cardId: cardId, imageData: imageData)
        }
    }

    func processUntaggedCards() {
        queue.async { [weak self] in
            self?.performProcessUntagged()
        }
    }

    private func performProcess(cardId: ObjectId, imageData: Data) {
        guard let realm = try? Realm(configuration: realmConfiguration),
              let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else {
            return
        }

        let ocrText = recognizeTextSync(from: imageData)
        let visionTags = classifyImageSync(from: imageData)

        do {
            try realm.write {
                card.ocrText = ocrText
                card.visionTags.removeAll()
                card.visionTags.append(objectsIn: visionTags)
            }
            Logger.postProcessor.notice("[PostProcess] card=\(cardId.stringValue) ocr=\(ocrText != nil) tags=\(visionTags.map(\.rawValue))")
        } catch {
            Logger.postProcessor.error("[PostProcess] Realm write failed: \(error.localizedDescription)")
        }
    }

    private func performProcessUntagged() {
        guard let realm = try? Realm(configuration: realmConfiguration) else { return }

        let allCards = realm.objects(Card.self)
        let untaggedCards = allCards.filter { $0.visionTags.isEmpty }

        Logger.postProcessor.notice("[PostProcess] Untagged cards: \(untaggedCards.count)/\(allCards.count)")

        for card in untaggedCards {
            guard let imageData = card.resolvedImageData() else { continue }
            let cardId = card.id

            let ocrText = recognizeTextSync(from: imageData)
            let visionTags = classifyImageSync(from: imageData)

            guard let freshCard = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { continue }

            do {
                try realm.write {
                    if freshCard.ocrText == nil {
                        freshCard.ocrText = ocrText
                    }
                    freshCard.visionTags.removeAll()
                    freshCard.visionTags.append(objectsIn: visionTags)
                }
            } catch {
                Logger.postProcessor.error("[PostProcess] Batch write failed: \(error.localizedDescription)")
            }
        }
    }

    private func recognizeTextSync(from imageData: Data) -> String? {
        guard let image = ImageDownsampler.downsample(data: imageData, maxDimension: 2000),
              let cgImage = image.cgImage else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ko-KR", "en-US", "ja-JP"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observations = request.results else { return nil }
        let texts = observations.compactMap { $0.topCandidates(1).first?.string }
        let fullText = texts.joined(separator: " ")
        return fullText.isEmpty ? nil : fullText
    }

    private func classifyImageSync(from imageData: Data) -> [VisionTag] {
        guard let image = ImageDownsampler.downsample(data: imageData, maxDimension: 500),
              let cgImage = image.cgImage else {
            return []
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observations = request.results else { return [] }
        let topLabels = observations.prefix(5).map { $0.identifier }
        return mapLabelsToVisionTags(topLabels)
    }

    func mapLabelsToVisionTags(_ labels: [String]) -> [VisionTag] {
        let labelMapping: [String: VisionTag] = [
            "person": .person, "face": .person, "people": .person, "human": .person, "portrait": .person, "selfie": .person,
            "cat": .cat, "kitten": .cat, "feline": .cat,
            "dog": .dog, "puppy": .dog, "canine": .dog,
            "bird": .bird,
            "food": .food, "meal": .food, "dish": .food, "fruit": .food, "vegetable": .food, "cuisine": .food, "dessert": .food, "bread": .food, "meat": .food, "pizza": .food,
            "drink": .drink, "beverage": .drink, "coffee": .drink, "tea": .drink,
            "nature": .nature, "landscape": .nature, "plant": .nature, "forest": .nature,
            "sky": .sky, "cloud": .sky,
            "sunset": .sunset, "sunrise": .sunset,
            "flower": .flower,
            "tree": .tree,
            "ocean": .ocean, "sea": .ocean, "beach": .ocean, "water": .ocean,
            "mountain": .mountain,
            "building": .building, "architecture": .building, "house": .building, "structure": .building, "tower": .building, "bridge": .building,
            "landmark": .landmark,
            "indoor": .indoor,
            "outdoor": .outdoor,
            "car": .car,
            "bicycle": .bicycle,
            "text": .text,
            "screenshot": .screenshot
        ]

        var result: [VisionTag] = []
        var seen = Set<VisionTag>()

        for label in labels {
            let lowercased = label.lowercased()
            for (keyword, tag) in labelMapping {
                if lowercased.contains(keyword) && !seen.contains(tag) {
                    result.append(tag)
                    seen.insert(tag)
                }
            }
        }

        return result
    }
}
