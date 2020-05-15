//
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Pulsator
import FontAwesome
import Common

protocol RegisterDeviceViewControllerDelegate: AnyObject {
}

final class RegisterDeviceViewController: UIViewController, ViewControllerInstantiatable {
    // MARK: - Dependency
    typealias Dependency = RegisterDeviceViewModelType
    
    // MARK: - Properties
    weak var delegate: RegisterDeviceViewControllerDelegate? = nil
    private lazy var viewModel: RegisterDeviceViewModelType = { fatalError("Use configure(with:) method at initialize controller") }()
    private let disposeBag = DisposeBag()
    
    //MARK: - UI Components
    @IBOutlet private weak var phoneView: UIImageView!
    @IBOutlet private weak var logTextView: UITextView!
    private let pulsator = Pulsator()
    
    // MARK: - Configure
    static func configure(with dependency: RegisterDeviceViewModelType = RegisterDeviceViewModel()) -> RegisterDeviceViewController {
        let viewController = RegisterDeviceViewController.instantiate()
        viewController.viewModel = dependency
        return viewController
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        phoneView.image = UIImage.fontAwesomeIcon(name: .mobileAlt,
                                                  style: .solid,
                                                  textColor: Asset.Colors.babyPowder.color,
                                                  size: CGSize(width: 100, height: 100))
        phoneView.layer.superlayer?.insertSublayer(pulsator, below: phoneView.layer)

        pulsator.numPulse = 3
        pulsator.radius = 200
        pulsator.fromValueForRadius = 0.5
        pulsator.backgroundColor = Asset.Colors.caribbeanGreen.color.withAlphaComponent(0.8).cgColor

        bind(to: viewModel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.layoutIfNeeded()
        pulsator.position = phoneView.layer.position
    }
}

// MARK: - Operation Methods
extension RegisterDeviceViewController {
}

// MARK: - Binding
extension RegisterDeviceViewController {
    private func bind(to viewModel: Dependency) {
        rx.viewDidAppear
            .map { _ in }
            .bind(to: viewModel.inputs.start)
            .disposed(by: disposeBag)

        viewModel.outputs.running
            .drive(onNext: { [weak self] in
                if $0 {
                    self?.pulsator.start()
                } else {
                    self?.pulsator.stop()
                }
            })
            .disposed(by: disposeBag)

        viewModel.outputs.log
            .drive(logTextView.rx.text)
            .disposed(by: disposeBag)
    }
}

// MARK: - StoryboardInstantiable
extension RegisterDeviceViewController: StoryboardInstantiable {}
