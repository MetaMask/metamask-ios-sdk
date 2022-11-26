//
//  Connection.swift
//  
//
//  Created by Mpendulo Ndlovu on 2022/11/01.
//

import Foundation

extension Sequence {
    var first: Element? {
        var iterator = self.makeIterator()
        return iterator.next()
    }
}
