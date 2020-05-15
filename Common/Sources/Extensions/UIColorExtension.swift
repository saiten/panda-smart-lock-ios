//
// Snippets
//

import UIKit

public extension UIColor {
    func toImage(size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.setFillColor(self.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

public extension UIColor {
    enum DecodeError: Error {
        case invalidFormat
    }

    convenience init(rgbaValue: UInt32) {
        let red   = CGFloat((rgbaValue >> 24) & 0xff) / 255.0
        let green = CGFloat((rgbaValue >> 16) & 0xff) / 255.0
        let blue  = CGFloat((rgbaValue >>  8) & 0xff) / 255.0
        let alpha = CGFloat((rgbaValue      ) & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    convenience init(hexString: String) throws {
        let offset = hexString.hasPrefix("#") ? 1 : 0
        let slice: String = String(hexString.dropFirst(offset))
        var rgbValue: UInt32 = 0
        guard Scanner(string: slice).scanHexInt32(&rgbValue) else {
            throw DecodeError.invalidFormat
        }
        let rgbaValue: UInt32 = (rgbValue << 8) | 0xFF
        self.init(rgbaValue: rgbaValue)
    }
}
