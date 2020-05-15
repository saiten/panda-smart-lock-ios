//
// Snippets
//

import UIKit

public extension UIView {
    var flattenedSubviews: [UIView] {
        return flattenSubviews(subviews)
    }
}

private func flattenSubviews(_ node: [UIView]) -> [UIView] {
    return node + node.flatMap { flattenSubviews($0.subviews) }
}

public extension UIView {
    func snapshotBackgroundColors() -> [(UIView, UIColor?)] {
        return flattenedSubviews.map { view in
            return (view, view.backgroundColor)
        }
    }

    func restoreBackgroundColors(_ state: [(UIView, UIColor?)]) {
        for (view, color) in state {
            view.backgroundColor = color
        }
    }
}

public extension UIView {
    // ViewからViewControllerを取得する
    func findViewController() -> UIViewController? {
        var nextResponder: UIResponder? = self
        while let responder = nextResponder {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            nextResponder = responder.next
        }
        return nil
    }
}
