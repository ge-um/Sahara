//
//  EXIFMetadataExtractorTests.swift
//  SaharaTests
//

import CoreLocation
import ImageIO
import XCTest
@testable import Sahara

final class EXIFMetadataExtractorTests: XCTestCase {

    private func createJPEGDataWithEXIF(
        dateTimeOriginal: String? = nil,
        tiffDateTime: String? = nil,
        latitude: Double? = nil,
        latitudeRef: String? = nil,
        longitude: Double? = nil,
        longitudeRef: String? = nil
    ) -> Data? {
        let size = CGSize(width: 10, height: 10)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        guard let cgImage = image.cgImage else { return nil }

        let mutableData = CFDataCreateMutable(nil, 0)!
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return nil }

        var metadata = [String: Any]()

        if dateTimeOriginal != nil || tiffDateTime != nil {
            if let dateTimeOriginal = dateTimeOriginal {
                var exifDict = [String: Any]()
                exifDict[kCGImagePropertyExifDateTimeOriginal as String] = dateTimeOriginal
                metadata[kCGImagePropertyExifDictionary as String] = exifDict
            }
            if let tiffDateTime = tiffDateTime {
                var tiffDict = [String: Any]()
                tiffDict[kCGImagePropertyTIFFDateTime as String] = tiffDateTime
                metadata[kCGImagePropertyTIFFDictionary as String] = tiffDict
            }
        }

        if let latitude = latitude, let longitude = longitude {
            var gpsDict = [String: Any]()
            gpsDict[kCGImagePropertyGPSLatitude as String] = latitude
            gpsDict[kCGImagePropertyGPSLongitude as String] = longitude
            if let latRef = latitudeRef {
                gpsDict[kCGImagePropertyGPSLatitudeRef as String] = latRef
            }
            if let lonRef = longitudeRef {
                gpsDict[kCGImagePropertyGPSLongitudeRef as String] = lonRef
            }
            metadata[kCGImagePropertyGPSDictionary as String] = gpsDict
        }

        CGImageDestinationAddImage(
            destination,
            cgImage,
            metadata as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }

    func test_extractFromData_parsesDateTimeOriginal() {
        guard let data = createJPEGDataWithEXIF(dateTimeOriginal: "2025:06:15 14:30:00") else {
            XCTFail("Failed to create test JPEG data")
            return
        }

        let result = EXIFMetadataExtractor.extract(from: data)

        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result.date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 30)
    }

    func test_extractFromData_fallsBackToTIFFDateTime() {
        guard let data = createJPEGDataWithEXIF(tiffDateTime: "2024:12:25 09:00:00") else {
            XCTFail("Failed to create test JPEG data")
            return
        }

        let result = EXIFMetadataExtractor.extract(from: data)

        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: result.date!)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 25)
    }

    func test_extractFromData_parsesGPSNorthEast() {
        guard let data = createJPEGDataWithEXIF(
            latitude: 37.5665,
            latitudeRef: "N",
            longitude: 126.9780,
            longitudeRef: "E"
        ) else {
            XCTFail("Failed to create test JPEG data")
            return
        }

        let result = EXIFMetadataExtractor.extract(from: data)

        XCTAssertNotNil(result.location)
        XCTAssertEqual(result.location!.coordinate.latitude, 37.5665, accuracy: 0.001)
        XCTAssertEqual(result.location!.coordinate.longitude, 126.9780, accuracy: 0.001)
    }

    func test_extractFromData_parsesGPSSouthWest() {
        guard let data = createJPEGDataWithEXIF(
            latitude: 33.8688,
            latitudeRef: "S",
            longitude: 151.2093,
            longitudeRef: "W"
        ) else {
            XCTFail("Failed to create test JPEG data")
            return
        }

        let result = EXIFMetadataExtractor.extract(from: data)

        XCTAssertNotNil(result.location)
        XCTAssertEqual(result.location!.coordinate.latitude, -33.8688, accuracy: 0.001)
        XCTAssertEqual(result.location!.coordinate.longitude, -151.2093, accuracy: 0.001)
    }

    func test_extractFromData_returnsNilForImageWithoutEXIF() {
        let size = CGSize(width: 10, height: 10)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            XCTFail("Failed to create JPEG data")
            return
        }

        let result = EXIFMetadataExtractor.extract(from: data)

        XCTAssertNil(result.date)
        XCTAssertNil(result.location)
    }

    func test_extractFromMetadata_parsesDateTimeOriginal() {
        let metadata: [String: Any] = [
            kCGImagePropertyExifDictionary as String: [
                kCGImagePropertyExifDateTimeOriginal as String: "2025:03:10 12:00:00"
            ]
        ]

        let result = EXIFMetadataExtractor.extract(from: metadata)

        XCTAssertNotNil(result.date)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: result.date!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 10)
    }

    func test_extractFromMetadata_locationIsAlwaysNil() {
        let metadata: [String: Any] = [
            kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 37.0,
                kCGImagePropertyGPSLongitude as String: 127.0
            ]
        ]

        let result = EXIFMetadataExtractor.extract(from: metadata)

        XCTAssertNil(result.location)
    }

    func test_extractFromMetadata_returnsNilForEmptyDict() {
        let result = EXIFMetadataExtractor.extract(from: [:])

        XCTAssertNil(result.date)
        XCTAssertNil(result.location)
    }
}
