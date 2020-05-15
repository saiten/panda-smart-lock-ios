// 
//  Copyright © 2020 saiten. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

public protocol SmartLockDeviceManagerProtocol {
    var currentDevice: Observable<SmartLockDeviceProtocol?> { get }
    var running: Observable<Bool> { get }
    
    func start(mode: SmartLockDeviceMode)
    func stop()
}

public extension SmartLockDeviceManagerProtocol {
    func start() {
        start(mode: .default)
    }
}

public final class SmartLockDeviceManager: SmartLockDeviceManagerProtocol {
    
    // MARK : - Properties

    public static let shared: SmartLockDeviceManagerProtocol = SmartLockDeviceManager()

    public let currentDevice: Observable<SmartLockDeviceProtocol?>
    public let running: Observable<Bool>
    
    private let _currentDevice: BehaviorRelay<SmartLockDeviceProtocol?>
    private let _mode: BehaviorRelay<SmartLockDeviceMode?>

    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    public init(smartLockDeviceService: SmartLockDeviceServiceProtocol = SmartLockDeviceService()) {
        self._currentDevice = BehaviorRelay(value: nil)
        self._mode = BehaviorRelay(value: nil)
        self.currentDevice = _currentDevice.asObservable()
        self.running = _mode.map { $0 != nil}.asObservable()

        Observable.combineLatest(_mode, _currentDevice)
            .filter { $0 != nil && $1 == nil }
            .flatMapLatest { (mode, _) -> Observable<SmartLockDeviceProtocol?> in
                guard let mode = mode else { return .just(nil) }
                return smartLockDeviceService.scan(mode: mode, timeout: .infinity)
                    .map { Optional($0) }.asObservable()
            }
            .bind(to: _currentDevice)
            .disposed(by: disposeBag)
        
        // 切断されたら現在のデバイスを更新
        currentDevice
            .flatMapLatest { device -> Observable<Bool> in
                guard let device = device else { return .empty() }
                return device.observeConnection()
            }
            .filter { !$0 }
            .map { _ in nil }
            .bind(to: _currentDevice)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Operation Methods

    public func start(mode: SmartLockDeviceMode) {
        _mode.accept(mode)
    }
    
    public func stop() {
        _mode.accept(nil)
    }
}
