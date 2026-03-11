//
//  EXIFMetadataExtractor.swift
//  Sahara
//

import CoreLocation
import ImageIO

struct EXIFMetadata {
    let location: CLLocation?
    let date: Date?
}

enum EXIFMetadataExtractor {

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func extract(from data: Data) -> EXIFMetadata {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return EXIFMetadata(location: nil, date: nil)
        }

        let date = parseDate(from: properties)
        let location = parseLocation(from: properties)
        return EXIFMetadata(location: location, date: date)
    }

    static func extract(from metadata: [String: Any]) -> EXIFMetadata {
        let date = parseDate(from: metadata)
        return EXIFMetadata(location: nil, date: date)
    }

    private static func parseDate(from properties: [String: Any]) -> Date? {
        if let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                return exifDateFormatter.date(from: dateString)
            }
            if let dateString = exifDict[kCGImagePropertyExifDateTimeDigitized as String] as? String {
                return exifDateFormatter.date(from: dateString)
            }
        }

        if let tiffDict = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateString = tiffDict[kCGImagePropertyTIFFDateTime as String] as? String {
            return exifDateFormatter.date(from: dateString)
        }

        return nil
    }

    private static func parseLocation(from properties: [String: Any]) -> CLLocation? {
        guard let gpsDict = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double else {
            return nil
        }

        let latRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String
        let lonRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String

        let lat = (latRef == "S") ? -latitude : latitude
        let lon = (lonRef == "W") ? -longitude : longitude

        return CLLocation(latitude: lat, longitude: lon)
    }
}
