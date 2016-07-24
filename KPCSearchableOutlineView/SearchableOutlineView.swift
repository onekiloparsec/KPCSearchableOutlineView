//
//  SearchableOutlineView.swift
//  KPCSearchableOutlineView
//
//  Created by Cédric Foellmi on 16/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
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
    func searchableContent() -> String
    
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
        return self.searchableContent().hash
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

    var searchableKeyPaths = []

    private var filteredTreeController: NSTreeController?
    private var filter: String = ""

    public func filterNodesTree(withString newFilter: String?) throws {
        guard newFilter != nil && newFilter?.characters.count >= 2, let filter = newFilter else {
            self.filter = ""
            self.messageLabel?.hidden = true
//            [self.outlineScrollView setHidden:NO];
//            [self.filteredOutlineScrollView setHidden:YES];
            return
        }
        
        guard self.treeController != nil else {
            throw SearchableOutlineViewError.MissingTreeController
        }
        
        let flatNodes = recursivePreorderTraversal(self.treeController?.arrangedObjects.childNodes)
        let filteredNodes = flatNodes.filter({ $0.searchableContent().lowercaseString.rangeOfString(filter.lowercaseString) != nil })
        let filteredLeafNodes = filteredNodes.filter({ $0.children == nil || $0.children.count == 0 })
        
        
//        NSMutableDictionary *parentsNodes = [NSMutableDictionary dictionary];
//        NSMutableArray *rootNodes = [NSMutableArray array];
        
//        var parentsNodes: [SearchableNode] = []
        var rootNodes: [SearchableNode] = []

        // Rebuild the tree from the leaves...
        
        // Move aside all regular children into a temporary array
        for leafNode in filteredLeafNodes {
            if let parentNode = leafNode.parentNode() {
                if parentNode.originalChildren.count == 0 && parentNode.children.count > 0 {
                    parentNode.originalChildren.addObjectsFromArray(parentNode.children as [AnyObject])
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

        
//        [[filteredLeafNodes copy] enumerateObjectsUsingBlock:^(KPCNode *node, NSUInteger idx, BOOL *stop) {
//            KPCNode *activeNode = node;
//            KPCNode *activeNodeCopy = nil;
//            KPCNode *parentNodeCopy = nil;
//            
//            if ([[parentsNodes allKeys] containsObject:activeNode.parentNode.identifier]) {
//            parentNodeCopy = [parentsNodes objectForKey:activeNode.parentNode.identifier];
//            activeNodeCopy = [activeNode thinCopy];
//            activeNodeCopy.parentNode = parentNodeCopy;
//            }
//            else {
//            while (activeNode.parentNode) {
//            activeNodeCopy = [parentsNodes objectForKey:activeNode.identifier];
//            if (!activeNodeCopy) {
//            activeNodeCopy = [activeNode thinCopy];
//            }
//            parentNodeCopy = [activeNode.parentNode thinCopy];
//            activeNodeCopy.parentNode = parentNodeCopy;
//            [parentsNodes setObject:parentNodeCopy forKey:parentNodeCopy.identifier];
//            activeNode = activeNode.parentNode;
//            }
//            
//            NSAssert(parentNodeCopy.isRoot && parentNodeCopy.isCopy, @"Parent root node is not root?");
//            [rootNodes addObject:parentNodeCopy];
//            }
//            }];
        
        self.treeController?.content?.removeAllObjects()
        self.treeController?.rearrangeObjects()
        
        //	NSAssert(activeNode.isRoot, @"At this point, the active node should be root.");
        //        indexPath = indexPath.indexPathByAddingIndexInFront(activeNode.sectionIndex)
        
        //        var indexSet = NSMutableIndexSet()
        for (index, rootNode) in rootNodes.enumerate() {
            self.treeController?.insertObject(rootNode, atArrangedObjectIndexPath: NSIndexPath(index: index))
        }
     
        //        [self.filteredTreeController.content removeAllObjects];
        //        [self.filteredTreeController rearrangeObjects];
        //
        //        if (rootNodes) {
        //            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        //            [[rootNodes copy] enumerateObjectsUsingBlock:^(KPCNode *node, NSUInteger idx, BOOL *stop) {
        //                [self.filteredTreeController insertObject:node atArrangedObjectIndexPath:[node pathIndexPath]];
        //                [indexSet addIndex:[[node pathIndexPath] indexAtPosition:0]];
        //                }];
        //
        //            [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        //                [self.filteredOutlineView expandItem:[self.filteredOutlineView itemAtRow:idx] expandChildren:YES];
        //                }];
        //
        //            [self.messageLabel setHidden:YES];
        //            [self.outlineScrollView setHidden:YES];
        //            [self.filteredOutlineScrollView setHidden:NO];
        //        }
        //        else {
        //            [self.messageLabel setHidden:NO];
        //            [self.outlineScrollView setHidden:YES];
        //            [self.filteredOutlineScrollView setHidden:YES];
        //        }
        //    }
        
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

