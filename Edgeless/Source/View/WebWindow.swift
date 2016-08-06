//
//  WebWindow.swift
//
//
//  Created by Bingwen Fu on 12/11/15.
//
//

import Cocoa
import SwiftLinkPreview
import KVOController

class WebWindow: NSWindow {
    
    var webView: WebView!
    var searchView: SearchView!
    var topBar: ImageView!
    var appDelegate: AppDelegate?
    var bookmarkView: BookmarkView?
    
    override var canBecomeKeyWindow: Bool {
        return true
    }
    
    func applicationDidFinishLaunch() {
        movableByWindowBackground = true
        backgroundColor = NSColor.clearColor()
        if let v = contentView {
            searchView = SearchView(frame: v.bounds)
            searchView.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
            searchView.delegate = self
            
            webView = WebView(frame: v.bounds)
            webView.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
            webView.delegate = self
            //webView.customUserAgent = "firefox"
            
            let h:CGFloat = 50.0
            let y = v.frame.height-h
            topBar = ImageView(frame: NSMakeRect(0, y, v.frame.width, h))
            topBar.autoresizingMask = [.ViewMinYMargin, .ViewWidthSizable]
            topBar.wantsLayer = true
            topBar.delegate = self
            
            v.wantsLayer = true
            v.layer?.cornerRadius = 5.0
            v.layer?.masksToBounds = true
            v.addSubview(searchView)            
        }
    }
    
    func setWebWithURL(urlStr: String) {
        removeSearchView()
        webView.loadURL(urlStr)
    }
    
    func setToSearchView() {
        addSearchView()
        webView.loadURL("")
    }
    
    func removeSearchView() {
        webView.frame = contentView!.frame
        contentView!.addSubview(webView, positioned: .Below, relativeTo: searchView)
        contentView!.addSubview(topBar, positioned: .Above, relativeTo: webView)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.2
            self.searchView.animator().alphaValue = 0.0
        }) {
            self.searchView.removeFromSuperview()
        }
    }
    
    func addSearchView() {
        searchView.frame = contentView!.frame
        contentView!.addSubview(searchView)
        makeFirstResponder(searchView.searchTextField)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            self.searchView.animator().alphaValue = 1.0
        }) {
            self.webView.removeFromSuperview()
        }
    }
    
    func showBookmarkView() {
        // initialization
        if bookmarkView == nil {
            bookmarkView = BookmarkView(frame: NSZeroRect)
            bookmarkView?.delegate = self
            bookmarkView?.prepareToBeShown()
            self.KVOController = FBKVOController(observer: self)
            self.KVOController.observe(self.contentView, keyPath: "frame", options: .New) { (a, b, c) in
                if let v = self.contentView, b = self.bookmarkView {
                    b.frame = NSMakeRect(0, 0, b.frame.width, v.frame.height)
                    b.resize()
                }
            }
        }
        if let v = self.contentView {
            if bookmarkView?.superview == nil {
                bookmarkView?.frame = NSMakeRect(0, 0, 556, v.frame.height)
                bookmarkView?.resizeAndReload(DataManager.sharedInstance.bookmarkJson)
                v.addSubview(bookmarkView!)
                NSAnimationContext.runAnimationGroup({ context in
                    self.bookmarkView?.animator().alphaValue = 1.0
                    }, completionHandler: nil)
            } else {
                bookmarkView?.removeFromSuperview()
            }
        }
    }
    
    func saveCurrentPageToBookmark() {
        func onSuccess(result: [String: AnyObject]) {
            var dic = [String:String]()
            if let title = result["title"] as? String {
                dic["title"] = title
            }
            if let url = result["finalUrl"] as? NSURL {
                dic["url"] = url.absoluteString
            }
            if let imgs = result["images"] as? [String] {
                dic["imageURL"] = imgs[0]
            }
            DataManager.sharedInstance.addBookmark(dic)
        }
        
        func onError(error: PreviewError) {
            Swift.print(error)
        }

        if let url = webView.URL?.absoluteString {
            onGlobalThread() {
                let slp = SwiftLinkPreview()
                slp.preview(url , onSuccess: onSuccess, onError: onError)
            }
        }
    }
    
    override func sendEvent(event: NSEvent) {
        if event.type == .KeyDown {
            guard let key = event.characters else { return }
            //Swift.print(event.modifierFlags.rawValue, key, event.keyCode)
            switch event.modifierFlags.rawValue {
            case 1048840:
                leftCommandEventWithKey(key, event: event)
                return
            case 1048848:
                rightCommandEventWithKey(key, event: event)
                return
            case 11010336:
                optionEventWithKeycode(event.keyCode, event: event)
                return
                //case 524576, 524608:
                //    optionEventWithKey(key, keycode: event.keyCode, event: event)
            //    return
            default:
                break
            }
        }
        super.sendEvent(event)
    }
    
    func optionEventWithKeycode(keycode: UInt16, event: NSEvent) {
        let map : [UInt16:String] = [
            123 : "left",
            124 : "right",
            125 : "down",
            126 : "up"
        ]
        guard let c = map[keycode] else {
            Swift.print(#function, " Unhandled key code ", keycode)
            return
        }
        if let config = DataManager.sharedInstance.perferenceJson["option"][c].string {
            let arr = config.componentsSeparatedByString("-")
            if let f = NSScreen.mainScreen()?.frame {
                let x = CGFloat(Double(arr[0])!) * f.size.width
                let y = CGFloat(Double(arr[1])!) * f.size.height
                let w = CGFloat(Double(arr[2])!) * f.size.width
                let h = CGFloat(Double(arr[3])!) * f.size.height
                self.setFrame(NSMakeRect(x, y, w, h), display:true)
            }
        } else {
            Swift.print(event.modifierFlags, keycode, " key event is not handled ", #function)
        }
    }
    
    func leftCommandEventWithKey(key: String, event: NSEvent) {
        let dm = DataManager.sharedInstance
        switch key {
        case "1":
            setToSearchView()
        case "f", "\r":
            toggleFullScreen(nil)
        case "w":
            self.orderOut(self)
        case "r":
            webView.reload()
        case "y", "d":
            webView.extractFullScreenYoutubeVideo()
        case "n":
            appDelegate?.createNewWindow()
        case "s":
            saveCurrentPageToBookmark()
        case ",":
            system("open \(dm.preferencePath) \(dm.bookmarkPath)")
        case "`":
            showBookmarkView()
        default:
            if let url = dm.perferenceJson["left command"][key].string {
                setWebWithURL(url)
            } else {
                Swift.print(event.modifierFlags, key + " key event is not handled " + #function)
            }
        }
    }
    
    func rightCommandEventWithKey(key: String, event: NSEvent) {
        if let url = DataManager.sharedInstance.perferenceJson["right command"][key].string {
            setWebWithURL(url)
        } else {
            Swift.print(event.modifierFlags, key + " key event is not handled " + #function)
        }
    }
}