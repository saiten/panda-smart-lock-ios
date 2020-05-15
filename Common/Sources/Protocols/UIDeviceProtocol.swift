//
// Snippets
//

import UIKit

public protocol UIDeviceProtocol {
    var identifierForVendor: UUID? { get }
    var modelName: String { get }
    var systemName: String { get }
    var systemVersion: String { get }
    var userInterfaceIdiom: UIUserInterfaceIdiom { get }

    func setValue(_ value: Any?, forKey key: String)
    func rotate(to orientation: UIInterfaceOrientation)
}

extension UIDevice: UIDeviceProtocol {
    public var modelName: String {
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    public func rotate(to orientation: UIInterfaceOrientation) {
        setValue(orientation.rawValue, forKey: "orientation")
    }
}
