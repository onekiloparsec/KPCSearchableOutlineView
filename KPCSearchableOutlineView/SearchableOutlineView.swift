//
//  SearchableOutlineView.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


extension IndexPath {
        
    func indexPathByAddingIndexPath(_ indexPath: IndexPath?) -> IndexPath {
        var path = self
        if let ip = indexPath {
            for position in 0..<ip.count {
                path.append(ip.index(position, offsetBy: 0))
            }
        }
        return path
    }
    
    func indexPathByAddingIndexInFront(_ index: Int) -> IndexPath {
        let indexPath = IndexPath(index: index)
        return indexPath.indexPathByAddingIndexPath(self)
    }
}

public protocol SearchableNode: NSObjectProtocol {
    var children: NSMutableArray { get set }
    var originalChildren: NSMutableArray { get set }

    func hash() -> Int
    var searchableContent: String { get }
    
    func parentNode() -> SearchableNode?
    func indexPath() -> IndexPath
}

public extension Collection where Iterator.Element == SearchableNode {
    func indexOf(_ element: Iterator.Element) -> Index? {
        return index(where: { $0.hash() == element.hash() })
    }
}

public extension SearchableNode {
    // This assume the content in a node is always unique!
    func hash() -> Int {
        return self.searchableContent.hash
    }
    
    func indexPath() -> IndexPath {
        var indexPath = IndexPath()
        var activeNode: SearchableNode = self
        
        while activeNode.parentNode() != nil {
            let index = activeNode.parentNode()!.children.index(of: self)
            indexPath = indexPath.indexPathByAddingIndexInFront(index)
            activeNode = activeNode.parentNode()!
        }
        
        return indexPath
    }
}

enum SearchableOutlineViewError: Error {
    case missingTreeController
}

open class SearchableOutlineView: NSOutlineView {
    
    @IBOutlet var messageLabel: NSTextField?
    @IBOutlet var treeController: NSTreeController?

    fileprivate var filter: String = ""

    open func filterNodesTree(withString newFilter: String?) throws {
        guard newFilter != nil && newFilter?.characters.count >= 2, let filter = newFilter else {
            self.filter = ""
            self.messageLabel?.isHidden = true
            return
        }
        
        guard self.treeController != nil else {
            throw SearchableOutlineViewError.missingTreeController
        }
        
        guard let rootTreeNode = self.treeController?.arrangedObjects as AnyObject? else {
            return
        }
        
        self.filter = filter

        let proxyChildren = rootTreeNode.children as [NSTreeNode]?
        let flatNodes = recursivePreorderTraversal(proxyChildren!)
        let filteredNodes = flatNodes.filter({ $0.searchableContent.lowercased().range(of: filter.lowercased()) != nil })
        let filteredLeafNodes = filteredNodes.filter({ $0.children.count == 0 })
        
        if filteredLeafNodes.count == 0 {
            self.messageLabel?.isHidden = false
            self.messageLabel?.stringValue = "No elements found"
            return
        }
        
        var rootNodes: [SearchableNode] = []

        // Rebuild the tree from the leaves...
        
        // Move aside all regular children into a temporary array
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode() {
                if parentNode.originalChildren.count == 0 && parentNode.children.count > 0 {
                    parentNode.originalChildren.addObjects(from: parentNode.children as [AnyObject])
                    parentNode.children.removeAllObjects()
                }
            }
        }

        // Re-introduce only valid one.
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode() {
                parentNode.children.add(leafNode)
            }
            
            var rootNode = leafNode
            while rootNode.parentNode() != nil {
                rootNode = rootNode.parentNode()!
            }
            rootNodes.append(rootNode)
        }

        (self.treeController?.content as! NSMutableArray).removeAllObjects()
        self.treeController?.rearrangeObjects()
        
        let indexSet = NSMutableIndexSet()
        for (index, rootNode) in rootNodes.enumerated() {
            self.treeController?.insert(rootNode, atArrangedObjectIndexPath: IndexPath(index: index))
            indexSet.add(index)
        }
        
        for index in indexSet {
            self.expandItem(self.item(atRow: index), expandChildren: true)
        }
    }

    func recursivePreorderTraversal(_ nodes: [NSTreeNode]?) -> Array<SearchableNode> {
        if nodes == nil {
            return []
        }
        var result: [SearchableNode] = []
        result += nodes!.filter({ $0.representedObject != nil }).map({ return $0.representedObject! as! SearchableNode })
        for node in nodes! {
            result += recursivePreorderTraversal(node.children)
        }
        return result
    }
}

