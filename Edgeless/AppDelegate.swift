//
//  AppDelegate.swift
//  Youtube
//
//  Created by Bingwen Fu on 12/11/15.
//  Copyright (c) 2015 Bingwen Fu. All rights reserved.
//

import Cocoa
import WebKit
import SwiftyJSON

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: WebWindow!
    var w: NSWindowController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.appDelegate = self
        window.applicationDidFinishLaunch()
        DataManager.sharedInstance.initialize()
    }
    
    func applicationWillBecomeActive(notification: NSNotification) {
        window.orderFront(nil)
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.orderFront(nil)
        return true
    }
    
    func createNewWindow() {
        w = NSWindowController(windowNibName: "WebWindow")
        w.showWindow(self)
        if let wd = w.window as? WebWindow {
            wd.applicationDidFinishLaunch()
            wd.appDelegate = self
        }
    }
}
