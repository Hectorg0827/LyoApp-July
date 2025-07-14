//
//  Item.swift
//  LyoApp July
//
//  Created by Republica La Tuya  on 7/14/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
