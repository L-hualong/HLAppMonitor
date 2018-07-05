//
//  Store.swift
//  Pods
//
//  Created by zixun on 17/1/6.
//
//

import Foundation

open class Store: NSObject {
    open static let shared = Store()
    
    // 3.2(MB)
    private(set) var networkMB: Double = 0
    
    private var change:((Double)->())?
    open func addNetworkByte(_ byte:Int64) {
        self.networkMB += Double(max(byte, -1))
        self.change?(self.networkMB);
    }
    
    open func networkByteDidChange(change:@escaping (Double)->()) {
        self.change = change
        
        if self.networkMB > 0 {
            self.change!(self.networkMB);
        }
    }
}
