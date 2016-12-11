//
//  SearchableNode.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 11/12/2016.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Foundation

extension IndexPath {
    func indexPathByAddingIndexInFront(_ index: Int) -> IndexPath {
        let indexPath = IndexPath(index: index)
        return indexPath.appending(self)
    }
}

public protocol SearchableNode: NSObjectProtocol {
    var uuid: UUID { get }
    var childNodes: [SearchableNode] { get set }
    var originalChildNodes: [SearchableNode] { get set }
    var parentNode: SearchableNode? { get }
    func searchableContent() -> String
}

public extension Collection where Iterator.Element == SearchableNode {
    func indexOf(_ element: Iterator.Element) -> Index? {
        return index(where: { $0.uuid == element.uuid })
    }
}

public extension SearchableNode {
    
    func indexPath() -> IndexPath {
        var indexPath = IndexPath()
        var activeNode: SearchableNode = self

        while activeNode.parentNode != nil {
            if let index = activeNode.parentNode!.childNodes.indexOf(self) {
                indexPath = indexPath.indexPathByAddingIndexInFront(index)
                activeNode = activeNode.parentNode!
            }
            else {
                break
            }
        }
        
        return indexPath
    }
}
