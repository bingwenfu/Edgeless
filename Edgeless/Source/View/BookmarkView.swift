//
//  BookmarkView.swift
//  Youtube
//
//  Created by Bingwen Fu on 7/31/16.
//  Copyright © 2016 Bingwen Fu. All rights reserved.
//

import Foundation
import SwiftyJSON

class BookmarkView : NSVisualEffectView, NSTableViewDelegate, NSTableViewDataSource {
    
    var contentScrollView: NSScrollView!
    var contentTableView: NSTableView!
    var dataSource: JSON = [:]
    var delegate: WebWindow?
    let w:CGFloat = 556
    
    func prepareToBeShown() {
        self.addContentTableView()
        self.addShadow()
        self.alphaValue = 0.0
        
        self.wantsLayer = true
        self.material = .MediumLight
        self.blendingMode = .WithinWindow
        //self.layer?.borderColor = NSColor.redColor().CGColor
        //self.layer?.borderWidth = 4.0
        
        // tableview selection notification
        let sel = #selector(self.tableViewSelectionChanged(_:))
        let name = NSTableViewSelectionDidChangeNotification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: sel, name: name , object: nil)
    }
    
    func addContentTableView() {
        let nib = NSNib(nibNamed: "BookmarkCellView", bundle: NSBundle.mainBundle())
        let nameColumn = NSTableColumn(identifier: "name column")
        nameColumn.width = w
        contentTableView = NSTableView(frame:NSZeroRect)
        contentTableView.headerView = nil
        contentTableView.selectionHighlightStyle = .None
        contentTableView.backgroundColor = NSColor.clearColor()
        contentTableView.setDelegate(self)
        contentTableView.setDataSource(self)
        contentTableView.addTableColumn(nameColumn)
        contentTableView.registerNib(nib!, forIdentifier: "BookmarkCellView")
        
        contentScrollView = NSScrollView(frame:NSZeroRect)
        contentScrollView.documentView = contentTableView
        contentScrollView.hasVerticalScroller = true
        contentScrollView.drawsBackground = false
        addSubview(contentScrollView)
    }
    
    func addSectionTableView() {
        
    }
    
    func addShadow() {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.4)
        shadow.shadowOffset = CGSize(width: 5,height: 0)
        shadow.shadowBlurRadius = 2.0
        self.wantsLayer = true
        self.shadow = shadow
    }
    
    override func removeFromSuperview() {
        NSAnimationContext.runAnimationGroup({ (context) in
            self.animator().alphaValue = 0.0
            }) {
                super.removeFromSuperview()
        }
    }
    
    func resizeAndReload(dataSource: JSON) {
        let h = self.frame.height
        contentTableView.frame = NSMakeRect(0, 0, w, h)
        contentScrollView.frame = NSMakeRect(0, 0, w, h)
        
        self.dataSource = dataSource
        self.contentTableView.reloadData()
    }
    
    func resize() {
        let h = self.frame.height
        contentTableView.frame = NSMakeRect(0, 0, w, h)
        contentScrollView.frame = NSMakeRect(0, 0, w, h)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return dataSource.count
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 140
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("BookmarkCellView", owner: self) as! BookmarkCellView
        if let title = dataSource[row]["title"].string {
            cell.titleTextField.stringValue = title
        }
        if let imgUrl = dataSource[row]["imageURL"].string {
            ImageManager.sharedInstance.setImageToView(cell.ImgView, urlStr: imgUrl)
        }
        return cell
    }
    
    func tableViewSelectionChanged(notification: NSNotification) {
        let row = contentTableView.selectedRow
        if let url = dataSource[row]["url"].string {
            self.removeFromSuperview()
            delegate?.setWebWithURL(url)
        }
    }
}
