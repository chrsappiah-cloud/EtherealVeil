//
//  Item.swift
//  EtherealVeil
//
//  Created by Christopher Appiah-Thompson  on 22/4/2026.
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
