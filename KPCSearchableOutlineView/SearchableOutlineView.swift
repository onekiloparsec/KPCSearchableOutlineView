//
//  SearchableOutlineView.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

extension NSIndexPath {
    
    func lastIndex() -> Int {
        return self.indexAtPosition(self.length-1);
    }
    
    func indexPathByAddingIndexPath(indexPath: NSIndexPath?) -> NSIndexPath {
        var path = self.copy() as! NSIndexPath
        if let ip = indexPath {
            for position in 0..<ip.length {
                path = path.indexPathByAddingIndex(ip.indexAtPosition(position))
            }
        }
        return path
    }
    
    func indexPathByAddingIndexInFront(index: Int) -> NSIndexPath {
        let indexPath = NSIndexPath(index: index)
        return indexPath.indexPathByAddingIndexPath(self)
    }
}

public protocol SearchableNode: NSObjectProtocol {
    var children: NSMutableArray { get set }
    var originalChildren: NSMutableArray { get set }

    func hash() -> Int
    var searchableContent: String { get }
    
    func parentNode() -> SearchableNode?
    func indexPath() -> NSIndexPath
}

public extension CollectionType where Generator.Element == SearchableNode {
    func indexOf(element: Generator.Element) -> Index? {
        return indexOf({ $0.hash() == element.hash() })
    }
}

public extension SearchableNode {
    // This assume the content in a node is always unique!
    func hash() -> Int {
        return self.searchableContent.hash
    }
    
    func indexPath() -> NSIndexPath {
        var indexPath = NSIndexPath()
        var activeNode: SearchableNode = self
        
        while activeNode.parentNode() != nil {
            let index = activeNode.parentNode()!.children.indexOfObject(self)
            indexPath = indexPath.indexPathByAddingIndexInFront(index)
            activeNode = activeNode.parentNode()!
        }
        
        return indexPath
    }
}

enum SearchableOutlineViewError: ErrorType {
    case MissingTreeController
}

public class SearchableOutlineView: NSOutlineView {
    
    @IBOutlet var messageLabel: NSTextField?
    @IBOutlet var treeController: NSTreeController?

    private var filter: String = ""

    public func filterNodesTree(withString newFilter: String?) throws {
        guard newFilter != nil && newFilter?.characters.count >= 2, let filter = newFilter else {
            self.filter = ""
            self.messageLabel?.hidden = true
            return
        }
        
        guard self.treeController != nil else {
            throw SearchableOutlineViewError.MissingTreeController
        }
        
        self.filter = filter
        let flatNodes = recursivePreorderTraversal(self.treeController?.arrangedObjects.childNodes)
        let filteredNodes = flatNodes.filter({ $0.searchableContent.lowercaseString.rangeOfString(filter.lowercaseString) != nil })
        let filteredLeafNodes = filteredNodes.filter({ $0.children == nil || $0.children.count == 0 })
        
        if filteredLeafNodes.count == 0 {
            self.messageLabel?.hidden = false
            self.messageLabel?.stringValue = "No elements found"
            return
        }
        
        var rootNodes: [SearchableNode] = []

        // Rebuild the tree from the leaves...
        
        // Move aside all regular children into a temporary array
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode() {
                if parentNode.originalChildren.count == 0 && parentNode.children.count > 0 {
                    parentNode.originalChildren.addObjectsFromArray(parentNode.children as [AnyObject])
                    parentNode.children.removeAllObjects()
                }
            }
        }

        // Re-introduce only valid one.
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode() {
                parentNode.children.addObject(leafNode)
            }
            
            var rootNode = leafNode
            while rootNode.parentNode() != nil {
                rootNode = rootNode.parentNode()!
            }
            rootNodes.append(rootNode)
        }

        self.treeController?.content?.removeAllObjects()
        self.treeController?.rearrangeObjects()
        
        let indexSet = NSMutableIndexSet()
        for (index, rootNode) in rootNodes.enumerate() {
            self.treeController?.insertObject(rootNode, atArrangedObjectIndexPath: NSIndexPath(index: index))
            indexSet.addIndex(index)
        }
        
        for index in indexSet {
            self.expandItem(self.itemAtRow(index), expandChildren: true)
        }
    }

    func recursivePreorderTraversal(nodes: [NSTreeNode]?) -> Array<SearchableNode> {
        if nodes == nil {
            return []
        }
        var result: [SearchableNode] = []
        result += nodes!.filter({ $0.representedObject != nil }).map({ return $0.representedObject! as! SearchableNode })
        for node in nodes! {
            result += recursivePreorderTraversal(node.childNodes)
        }
        return result
    }
}

