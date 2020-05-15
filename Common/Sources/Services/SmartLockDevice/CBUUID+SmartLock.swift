// 
//  Copyright © 2019 saiten. All rights reserved.
//

import CoreBluetooth

extension CBUUID {
    // SmartLock Registration Service

    // 00008D01-0000-1000-8000-00805f9b34fb
    public static var smartLockRegistrationService = CBUUID(string: "8D01")

    public static var smartLockRegisterKeyCharacteristic = CBUUID(string: "9A234600-E549-4FE1-B5F3-A300529ED143")
    public static var smartLockVerifySignCharacteristic = CBUUID(string: "A7EE741F-6544-4058-93CA-8F3BD84F211C")
    
    // SmartLock Main Service
    
    // 00008D02-0000-1000-8000-00805f9b34fb
    public static var smartLockMainService = CBUUID(string: "8D02")
    
    public static var smartLockChallengeCharacteristic = CBUUID(string: "AFB54496-31DB-461B-8313-90A196CEA4D6")
    public static var smartLockOperationCharacteristic = CBUUID(string: "E570EB24-CB0C-4A1D-851D-F4A524DDE786")
}

extension Set where Element: CBUUID {

    public static var smartLockRegistrationServiceCharacteristics: Set<CBUUID> {
        return [.smartLockRegisterKeyCharacteristic, .smartLockVerifySignCharacteristic]
    }
    
    public static var smartLockMainServiceCharacteristics: Set<CBUUID> {
        return [.smartLockChallengeCharacteristic, .smartLockOperationCharacteristic]
    }

}
