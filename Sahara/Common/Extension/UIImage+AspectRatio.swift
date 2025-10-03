import UIKit

extension UIImage {
    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let aspectRatio = size.height / size.width
        return width * aspectRatio
    }
}
