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
        
        self.outlineView?.delegate = self
        self.searchField?.delegate = self
        
        self.nodes = []
        self.selectionIndexPaths = []

        self.loadWebsitesPlistFile()
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellView: NSTableCellView = self.outlineView?.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("DataCell"), owner:nil) as! NSTableCellView
        let node = (item as AnyObject).representedObject as! BaseNode
        if let title = node.nodeTitle {
            cellView.textField?.stringValue = title
        }
        else {
            cellView.textField?.stringValue = "?"
        }
        if node.childNodes.count > 0 {
            cellView.imageView?.image = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(UInt32(kGenericFolderIcon)))
        }
        else {
            cellView.imageView?.image = nil
        }
        return cellView
    }
        
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return false
    }

    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        Swift.print("Start Searching")
    }
    
    func controlTextDidChange(_ notification: Notification) {
        if let searchField = notification.object as? NSSearchField {
            if searchField.stringValue.count >= 3 {
                Swift.print("Searching: \(searchField.stringValue)...")
                try! self.outlineView?.filterNodesTree(withString: searchField.stringValue)
            }
        }
    }
    
    func loadWebsitesPlistFile() {
        self.treeController?.selectsInsertedObjects = true
        
        let path = Bundle.main.path(forResource: "DefaultWebsites", ofType:"dict")!
        let url = URL(fileURLWithPath: path)
        let data = try? Data(contentsOf: url)
        let plist = try! PropertyListSerialization.propertyList(from: data!, options: .mutableContainers, format: nil) as! NSDictionary
        let entries: [[String: AnyObject]] = plist.object(forKey: "entries")! as! [[String : AnyObject]]

        self.loadWebsiteEntries(entries, rootNode: nil)
    }
    
    func loadWebsiteEntries(_ entries: [[String: AnyObject]], rootNode: BaseNode?) {
        
        for entry in entries {
            let groupName = entry["group"] as! String
            let groupEntries = entry["entries"] as! [[String: AnyObject]]
            
            let groupNode = BaseNode()
            groupNode.nodeTitle = groupName
            Swift.print("GroupNode \(groupNode.nodeTitle!)")
            
            if rootNode != nil {
                groupNode.parentNode = rootNode
                rootNode!.childNodes.append(groupNode)
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
                    node.parentNode = groupNode
                    groupNode.childNodes.append(node)
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


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
	return NSUserInterfaceItemIdentifier(rawValue: input)
}
