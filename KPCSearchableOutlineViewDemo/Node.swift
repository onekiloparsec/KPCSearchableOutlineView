//
//  Node.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/07/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Cocoa
import KPCSearchableOutlineView

@objc class BaseNode: NSObject, SearchableNode {

    var nodeTitle: String? = nil
    var url: String? = nil
    var children: NSMutableArray = NSMutableArray()
    var originalChildren: NSMutableArray = NSMutableArray()
    weak var parent: SearchableNode?
    
    var searchableContent: String {
        get { return (self.nodeTitle == nil) ? "" : self.nodeTitle! }
    }
    
    func parentNode() -> SearchableNode? {
        return self.parent
    }
    
    func isLeaf() -> Bool {
        return self.children.count == 0
    }
}