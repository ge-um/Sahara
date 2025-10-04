import LinkPresentation
import UIKit

final class ShareActivityItemSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let appName: String

    init(image: UIImage) {
        self.image = image
        self.appName = NSLocalizedString("common.app_name", comment: "")
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = appName
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}
