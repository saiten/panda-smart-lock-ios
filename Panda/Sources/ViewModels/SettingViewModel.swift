// 
//  Copyright © 2019 saiten. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import RxDataSources

enum SettingMenu {
    case registerKey
    case about
    
    var title: String {
        switch self {
        case .registerKey:
            return "Register key"
        case .about:
            return "About app"
        }
    }
}

protocol SettingViewModelInputs {
}

protocol SettingViewModelOutputs {
    var menu: Observable<[SectionModel<String, SettingMenu>]> { get }
}

protocol SettingViewModelType {
    var inputs: SettingViewModelInputs { get }
    var outputs: SettingViewModelOutputs { get }
}

final class SettingViewModel: SettingViewModelType, SettingViewModelInputs, SettingViewModelOutputs {
    // MARK: - Properties
    var inputs: SettingViewModelInputs { return self }
    var outputs: SettingViewModelOutputs { return self }
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    
    // MARK: - Outputs
    let menu: Observable<[SectionModel<String, SettingMenu>]>
    
    // MARK: - Initializer
    init() {
        self.menu = .just([
            SectionModel(model: "Smart Lock", items: [.registerKey]),
            SectionModel(model: "Other", items: [.about]),
        ])
    }
}
