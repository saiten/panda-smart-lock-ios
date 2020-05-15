//
// Snippets
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

public extension UIViewController {
    func addContainerViewController(_ viewController: UIViewController?, targetView: UIView) {
        guard let viewController = viewController else { return }
        guard !children.contains(viewController) else { return }
        viewController.view.frame = targetView.bounds
        addChild(viewController)
        targetView.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        viewController.didMove(toParent: self)
        targetView.layoutIfNeeded()
    }

    func removeContainerViewController(_ viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        viewController.view.layer.removeAllAnimations()
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    func removeFromSuperViewController() {
        view.layer.removeAllAnimations()
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

public extension UIViewController {
    var parentControllers: [UIViewController] {
        var viewControllers = [UIViewController]()
        var viewController: UIViewController? = self
        while viewController != nil {
            viewController = viewController?.parent
            if let parentViewController = viewController {
                viewControllers.append(parentViewController)
            }
        }
        return viewControllers
    }

    func containsParentViewController<T: UIViewController>(_ type: T.Type) -> Bool {
        return parentControllers.contains(where: { $0 is T })
    }
}

public extension UIViewController {
    // レイアウトの即時更新を行わずにViewControllerをコンテナへ追加する．
    // `layoutIfNeeded` によって発生するメインスレッドにおけるブロッキングを回避する．
    // このときレイアウトのタイミングはUIKit依存となる点に注意する．
    // ViewControllerが頻繁に切り替わる場所において有効である．
    func addContainerViewControllerWithoutLayout(_ viewController: UIViewController?, targetView: UIView) {
        guard let viewController = viewController else { return }
        guard !children.contains(viewController) else { return }
        addChild(viewController)
        targetView.addSubview(viewController.view)
        viewController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        viewController.didMove(toParent: self)
        targetView.setNeedsLayout()
    }
}

public extension UIViewController {
    var isNavigationRootViewConttoller: Bool {
        guard let navigationController = self.navigationController else { return true }
        return navigationController.viewControllers.first == self
    }
}

public extension UIViewController {
    var isViewVisible: Bool {
        return isViewLoaded && view.window != nil
    }
}

public extension Reactive where Base: UIViewController {
    var viewDidLayoutSubviews: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews)).map { _ in }
        return ControlEvent(events: source)
    }

    var viewDidAppear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewDidAppear)).map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }

    var viewSafeAreaInsetsDidChange: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewSafeAreaInsetsDidChange)).map { _ in }
        return ControlEvent(events: source)
    }
}
