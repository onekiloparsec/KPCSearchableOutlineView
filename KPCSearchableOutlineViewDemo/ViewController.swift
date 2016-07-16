//
//  ViewController.swift
//  KPCSearchableOutlineViewDemo
//
//  Created by Cédric Foellmi on 18/05/16.
//  Copyright © 2016 onekiloparsec. All rights reserved.
//

import Cocoa
import KPCSearchableOutlineView

class ViewController: NSViewController, NSOutlineViewDelegate {
    
    @IBOutlet weak var outlineView: SearchableOutlineView?
    @IBOutlet var treeController: NSTreeController?
    @IBOutlet var nodes: NSArray?
    @IBOutlet var selectionIndexPaths: NSArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.outlineView?.setDelegate(self)
        
        self.nodes = []
        self.selectionIndexPaths = []

        let path = NSBundle.mainBundle().pathForResource("DefaultWebsites", ofType:"dict")!
        let url = NSURL(fileURLWithPath: path)
        let data = NSData(contentsOfURL: url)
        let plist = try! NSPropertyListSerialization.propertyListWithData(data!, options: .MutableContainers, format: nil) as! NSDictionary

        let entries: [[String: AnyObject]] = plist.objectForKey("entries")! as! [[String : AnyObject]]
        
        print("\(plist)")
        
        for entry in entries {
            let groupName = entry["group"] as! String
            let groupEntries = entry["entries"] as! [[String: AnyObject]]
            
            let groupNode = BaseNode()
            groupNode.nodeTitle = groupName
            groupNode.children = []
            groupNode.originalChildren = []
            
            for groupEntry in groupEntries {
                let node = BaseNode()
                node.nodeTitle = groupEntry["name"] as? String
                node.url = groupEntry["url"] as? String
                node.parent = groupNode
                groupNode.children?.append(node)
            }
            
            self.treeController?.add(groupNode)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let cellView: DataCellView = self.outlineView?.makeViewWithIdentifier("DataCell", owner:nil) as! DataCellView
        let node = item.representedObject!! as! BaseNode
        if let title = node.nodeTitle {
            cellView.nodeTitle = title
        }
        else {
            cellView.nodeTitle = "?"            
        }
        return cellView
    }
    
//        NSEnumerator *entryEnum = [entries objectEnumerator];
//    
//    id entry;
//    while ((entry = [entryEnum nextObject])) {
//    if ([entry isKindOfClass:[NSDictionary class]]) {
//    NSString *urlStr = [entry objectForKey:KEY_URL];
//    
//    BaseNode *node = [BaseNode nodeWithTitle:nil];
//    [node setNodeURL:urlStr];
//    [node setNodeSectionIndex:index];
//    [node setSelectParent:YES];
//    if (index == kWebsitesSectionIndex) {
//				[node setNodeIcon:(STLSmartImage *)[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericURLIcon)]];
//    }
//    else if (index == kConvertersSectionIndex) {
//				[node setNodeIcon:[STLSmartImage imageNamed:@"ConverterIcon.icns"]];
//    }
//    
//    if ([entry objectForKey:KEY_SEPARATOR]) {
//    [self insertChildNode:node];
//				[self.treeController selectParentFromSelection];
//    }
//    else if ([entry objectForKey:KEY_FOLDER]) {
//    [node setNodeTitle:[entry objectForKey:KEY_FOLDER]];
//    [self insertChildNode:node];
//				[self.treeController selectParentFromSelection];
//    }
//    else if ([entry objectForKey:KEY_URL]) {
//    [node setNodeTitle:[entry objectForKey:KEY_NAME]];
//    [self insertChildNode:node];
//				[self.treeController selectParentFromSelection];
//    }
//    else {
//				NSString *folderName = [entry objectForKey:KEY_GROUP];
//				[self addFolder:folderName inSection:index root:NO];
//				NSArray *entries = [entry objectForKey:KEY_ENTRIES];
//				[self addEntries:entries inSection:index];
//				[self.treeController selectParentFromSelection];
//				[self.outlineView collapseItem:[self.outlineView itemAtRow:[self.outlineView selectedRow]]];
//    }
//    }
//    }
//    }
//
}

