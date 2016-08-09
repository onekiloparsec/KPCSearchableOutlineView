//
//  ViewController.swift
//  KPCSearchableOutlineViewDemo
//
//  Created by Cédric Foellmi on 18/05/16.
//  Licensed under the MIT License (see LICENSE file)
//

import Cocoa
import KPCSearchableOutlineView

class ViewController: NSViewController, NSOutlineViewDelegate, NSSearchFieldDelegate {
    
    @IBOutlet weak var outlineView: SearchableOutlineView?
    @IBOutlet weak var searchField: NSSearchField?

    @IBOutlet var treeController: NSTreeController?
    @IBOutlet var nodes: NSMutableArray?
    @IBOutlet var selectionIndexPaths: NSMutableArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.outlineView?.setDelegate(self)
        self.searchField?.delegate = self
        
        self.nodes = []
        self.selectionIndexPaths = []

        self.loadWebsitesPlistFile()
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let cellView: NSTableCellView = self.outlineView?.makeViewWithIdentifier("DataCell", owner:nil) as! NSTableCellView
        let node = item.representedObject as! BaseNode
        if let title = node.nodeTitle {
            cellView.textField?.stringValue = title
        }
        else {
            cellView.textField?.stringValue = "?"
        }
        if node.children.count > 0 {
            cellView.imageView?.image = NSWorkspace.sharedWorkspace().iconForFileType(NSFileTypeForHFSTypeCode(UInt32(kGenericFolderIcon)))
        }
        else {
            cellView.imageView?.image = nil
        }
        return cellView
    }
        
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        return false
    }

    func searchFieldDidStartSearching(sender: NSSearchField) {
        Swift.print("Start Searching")
    }
    
    override func controlTextDidChange(notification: NSNotification) {
        if let searchField = notification.object as? NSSearchField {
            if searchField.stringValue.characters.count >= 3 {
                Swift.print("Searching: \(searchField.stringValue)...")
                try! self.outlineView?.filterNodesTree(withString: searchField.stringValue)
            }
        }
    }
    
    func loadWebsitesPlistFile() {
        self.treeController?.selectsInsertedObjects = true
        
        let path = NSBundle.mainBundle().pathForResource("DefaultWebsites", ofType:"dict")!
        let url = NSURL(fileURLWithPath: path)
        let data = NSData(contentsOfURL: url)
        let plist = try! NSPropertyListSerialization.propertyListWithData(data!, options: .MutableContainers, format: nil) as! NSDictionary
        let entries: [[String: AnyObject]] = plist.objectForKey("entries")! as! [[String : AnyObject]]

        self.loadWebsiteEntries(entries, rootNode: nil)
    }
    
    func loadWebsiteEntries(entries: [[String: AnyObject]], rootNode: BaseNode?) {
        
        for entry in entries {
            let groupName = entry["group"] as! String
            let groupEntries = entry["entries"] as! [[String: AnyObject]]
            
            let groupNode = BaseNode()
            groupNode.nodeTitle = groupName
            Swift.print("GroupNode \(groupNode.nodeTitle!)")
            
            if rootNode != nil {
                groupNode.parent = rootNode
                rootNode!.children.addObject(groupNode)
                self.treeController?.addChild(groupNode)
            }
            else {
                self.treeController?.addObject(groupNode)
            }
            self.treeController?.rearrangeObjects()
            
            for groupEntry in groupEntries {
                if groupEntry["name"] != nil {
                    let node = BaseNode()
                    node.nodeTitle = (groupEntry["name"] as! String)
                    node.url = (groupEntry["url"] as! String)
                    node.parent = groupNode
                    groupNode.children.addObject(node)
                    self.treeController?.addChild(groupNode)
                    self.treeController?.rearrangeObjects()
                }
                else if groupEntry["entries"] != nil {
                    self.loadWebsiteEntries(groupEntry["entries"] as! [[String: AnyObject]], rootNode: groupNode)
                }
            }
        }
        
        
    }
}

