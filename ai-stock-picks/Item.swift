//
//  Item.swift
//  ai-stock-picks
//
//  Created by user944521 on 10/6/25.
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
