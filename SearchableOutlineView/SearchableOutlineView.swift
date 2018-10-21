//
//  SearchableOutlineView.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import AppKit

enum SearchableOutlineViewError: Error {
    case missingTreeController
}

open class SearchableOutlineView: NSOutlineView {
    
    @IBOutlet open var messageLabel: NSTextField?
    @IBOutlet open var treeController: NSTreeController?

    fileprivate var filter: String = ""

    open func filterNodesTree(withString newFilter: String?) throws {
        guard newFilter != nil && newFilter!.count >= 2, let filter = newFilter else {
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
        let filteredNodes = flatNodes.filter({ $0.searchableContent().lowercased().range(of: filter.lowercased()) != nil })
        let filteredLeafNodes = filteredNodes.filter({ $0.childNodes.count == 0 })
        
        if filteredLeafNodes.count == 0 {
            self.messageLabel?.isHidden = false
            self.messageLabel?.stringValue = "No elements found"
            return
        }
        
        var rootNodes: [SearchableNode] = []

        // Rebuild the tree from the leaves...
        
        // Move aside all regular children into a temporary array
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode {
                if parentNode.originalChildNodes.count == 0 && parentNode.childNodes.count > 0 {
                    parentNode.originalChildNodes.append(contentsOf: parentNode.childNodes)
                    parentNode.childNodes.removeAll()
                }
            }
        }

        // Re-introduce only valid one.
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode {
                parentNode.childNodes.append(leafNode)
            }
            
            var rootNode = leafNode
            while rootNode.parentNode != nil {
                rootNode = rootNode.parentNode!
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

