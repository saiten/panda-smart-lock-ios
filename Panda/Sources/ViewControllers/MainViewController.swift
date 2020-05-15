// 
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Lottie
import SnapKit
import PKHUD
import Common

final class MainViewController: UIViewController, ViewControllerInstantiatable {
    // MARK: - Dependency
    typealias Dependency = MainViewModelType

    // MARK: - UI Components
    @IBOutlet private weak var settingButton: UIButton!
    @IBOutlet private weak var unlockButton: UIButton!
    @IBOutlet private weak var lockButton: UIButton!
    @IBOutlet private weak var pandaContainerView: UIView!    
    // MARK: - Properties
    private lazy var viewModel: MainViewModelType = { fatalError("Use configure(with:) method at initialize controller") }()
    private let disposeBag = DisposeBag()
    
    // MARK: - Configure
    static func configure(with dependency: MainViewModelType = MainViewModel()) -> MainViewController {
        let viewController = MainViewController.instantiate()
        viewController.viewModel = dependency
        return viewController
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        bind(to: viewModel)
    }
}

// MARK: - Operation Methods
extension MainViewController {
    func unlock() {
        viewModel.inputs.unlockRequest.accept(())
    }

    func lock() {
        viewModel.inputs.lockRequest.accept(())
    }
}

// MARK: - Binding
extension MainViewController {
    private func bind(to viewModel: Dependency) {
        lockButton.rx.tap
            .bind(to: viewModel.inputs.lockRequest)
            .disposed(by: disposeBag)
        unlockButton.rx.tap
            .bind(to: viewModel.inputs.unlockRequest)
            .disposed(by: disposeBag)

        viewModel.outputs.loading
            .drive(onNext: { [weak self] loading in
                if loading {
                    HUD.show(.progress)
                }
                self?.lockButton.isEnabled = !loading
                self?.unlockButton.isEnabled = !loading
            })
            .disposed(by: disposeBag)

        viewModel.outputs.lockButtonEnabled
            .drive(lockButton.rx.isEnabled)
            .disposed(by: disposeBag)
        viewModel.outputs.lockButtonEnabled
            .drive(unlockButton.rx.isEnabled)
            .disposed(by: disposeBag)

        Driver.merge(viewModel.outputs.lockSuccess.map { true },
                     viewModel.outputs.unlockSuccess.map { false })
            .drive(onNext: { locked in
                HUD.flash(.success, delay: 1.0)
            })
            .disposed(by: disposeBag)
        
        viewModel.outputs.failed
            .drive(onNext: { locked in
                HUD.flash(.error, delay: 1.0)
            })
            .disposed(by: disposeBag)

        settingButton.rx.tap
            .subscribe(onNext: { [weak self] in
                let controller = UINavigationController(rootViewController: SettingViewController.configure())
                self?.navigationController?.present(controller, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - StoryboardInstantiable
extension MainViewController: StoryboardInstantiable {}
