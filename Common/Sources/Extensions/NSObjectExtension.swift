//
// Snippets
//

import Foundation

public extension NSObject {
    static var className: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }

    var className: String {
        return type(of: self).className
    }
}
