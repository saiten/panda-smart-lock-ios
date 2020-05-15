// 
//  Copyright © 2019 saiten. All rights reserved.
//

import Foundation

public extension Data {
    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size)
            .map { self[$0 ..< Swift.min($0 + size, count)] }
    }
    
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
