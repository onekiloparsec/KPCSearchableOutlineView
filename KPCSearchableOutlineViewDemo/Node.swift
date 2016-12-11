//
//  Node.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/07/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Cocoa
import KPCSearchableOutlineView

@objc class BaseNode: NSObject, SearchableNode {

    var uuid = UUID()
    var nodeTitle: String? = nil
    var url: String? = nil
    var childNodes = [SearchableNode]()
    var originalChildNodes = [SearchableNode]()
    weak var parentNode: SearchableNode?

    var children: NSMutableArray {
        get { return NSMutableArray(array: self.childNodes) }
        set { self.childNodes = newValue.map {$0} as! [BaseNode] }
    }

    func searchableContent() -> String {
        return (self.nodeTitle == nil) ? "" : self.nodeTitle! 
    }
        
    func isLeaf() -> Bool {
        return self.childNodes.count == 0
    }
}
