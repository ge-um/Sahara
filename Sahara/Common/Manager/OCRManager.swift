//
//  OCRManager.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import UIKit
import Vision
import RxSwift

final class OCRManager {
    static let shared = OCRManager()

    private init() {}

    func recognizeText(from image: UIImage) -> Observable<String?> {
        return Observable.create { observer in
            guard let cgImage = image.cgImage else {
                observer.onNext(nil)
                observer.onCompleted()
                return Disposables.create()
            }

            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }

                let recognizedTexts = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                let fullText = recognizedTexts.joined(separator: " ")
                observer.onNext(fullText.isEmpty ? nil : fullText)
                observer.onCompleted()
            }

            request.recognitionLanguages = ["ko-KR", "en-US", "ja-JP"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    observer.onError(error)
                }
            }

            return Disposables.create()
        }
    }
}
