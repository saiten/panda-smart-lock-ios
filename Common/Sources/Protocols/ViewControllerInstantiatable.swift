//
// Snippets
//

import UIKit

public protocol ViewControllerInstantiatable: AnyObject {
    associatedtype Dependency
    static func configure(with dependency: Dependency) -> Self
}

public extension ViewControllerInstantiatable where Self: UIViewController, Self: StoryboardInstantiable, Dependency == Void {
    static func configure(with dependency: Dependency) -> Self {
        let controller = Self.instantiate()
        return controller
    }

    static func configure() -> Self {
        return Self.configure(with: ())
    }
}
