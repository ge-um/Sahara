import Foundation

enum AppNotification: String {
    case photoSaved = "PhotoSaved"
    case photoDeleted = "PhotoDeleted"

    var name: Notification.Name {
        return Notification.Name(rawValue)
    }
}
