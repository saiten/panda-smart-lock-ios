//
// Snippets
//

import UIKit

public protocol StoryboardInstantiable: AnyObject {
    static var storyboardName: String { get }
}

public extension StoryboardInstantiable where Self: UIViewController {
    static var storyboardName: String {
        return className
    }
}

public extension StoryboardInstantiable where Self: UIViewController {
    static func instantiate() -> Self {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.instantiateInitialViewController() as! Self // swiftlint:disable:this force_cast
    }
}
