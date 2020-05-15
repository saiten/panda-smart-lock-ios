// 
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import Common

protocol SettingViewControllerDelegate: AnyObject {
}

final class SettingViewController: UIViewController, ViewControllerInstantiatable {
    // MARK: - Dependency
    typealias Dependency = SettingViewModelType
    
    // MARK: - Properties
    weak var delegate: SettingViewControllerDelegate? = nil
    private lazy var viewModel: SettingViewModelType = { fatalError("Use configure(with:) method at initialize controller") }()
    private let disposeBag = DisposeBag()
    
    //MARK: - UI Components
    @IBOutlet private weak var closeButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - Configure
    static func configure(with dependency: SettingViewModelType = SettingViewModel()) -> SettingViewController {
        let viewController = SettingViewController.instantiate()
        viewController.viewModel = dependency
        return viewController
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bind(to: viewModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
}

// MARK: - Operation Methods
extension SettingViewController {
}

// MARK: - Binding
extension SettingViewController {
    private func bind(to viewModel: Dependency) {
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, SettingMenu>>(
            configureCell: { (_, tableView, indexPath, item) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                cell.textLabel?.text = item.title
                return cell
            },
            titleForHeaderInSection: { $0.sectionModels[$1].model }
        )

        viewModel.outputs.menu
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(SettingMenu.self)
            .subscribe(onNext: { [weak self] in
                switch $0 {
                case .registerKey:
                    let viewController = RegisterDeviceViewController.configure()
                    self?.navigationController?.pushViewController(viewController, animated: true)
                case .about:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - StoryboardInstantiable
extension SettingViewController: StoryboardInstantiable {}
