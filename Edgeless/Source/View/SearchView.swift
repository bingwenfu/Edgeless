//
//  SearchView.swift
//  
//
//  Created by Bingwen Fu on 12/11/15.
//
//

import Cocoa
import QuartzCore

class ImageView: NSImageView {
    
    var delegate: WebWindow?
    var oldLocation = NSEvent.mouseLocation()
    var oldFrame = NSZeroRect
    
    override func mouseDragged(theEvent: NSEvent) {
        let newLocation = NSEvent.mouseLocation()
        let dx = newLocation.x - oldLocation.x
        let dy = newLocation.y - oldLocation.y
        
        if let window = delegate {
            var rect = oldFrame
            rect.origin.x += dx
            rect.origin.y += dy
            window.setFrame(rect, display: true)
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        oldFrame = delegate!.frame
        oldLocation = NSEvent.mouseLocation()
    }
}

class SearchView: NSView, NSTextFieldDelegate {
    
    var searchTextField: NSTextField!
    var searchTextBackgroundLayer: CALayer!
    var delegate: WebWindow!
    var backgroundImageView: ImageView!
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        backgroundImageView = ImageView(frame: frameRect)
        backgroundImageView.image = randomImage()
        backgroundImageView.imageScaling = NSImageScaling.ScaleAxesIndependently
        backgroundImageView.autoresizingMask = [.ViewHeightSizable, .ViewWidthSizable]
        self.addSubview(backgroundImageView)
        
        searchTextBackgroundLayer = CALayer()
        searchTextBackgroundLayer.backgroundColor = NSColor.whiteColor().CGColor
        searchTextBackgroundLayer.opacity = 0.8
        searchTextBackgroundLayer.cornerRadius = 4
        layer?.addSublayer(searchTextBackgroundLayer)
        
        searchTextField = NSTextField()
        searchTextField.focusRingType = .None
        searchTextField.delegate = self
        searchTextField.font = NSFont(name: "Helvetica-Light", size: 28)
        searchTextField.bordered = false
        searchTextField.backgroundColor = NSColor.clearColor()
        addSubview(searchTextField)
    }
    
    override func layout() {
        super.layout()
        CATransaction.setDisableActions(true)
        setTextFieldFrame()
        CATransaction.setDisableActions(false)
        backgroundImageView.delegate = delegate
    }
    
    func randomImage() -> NSImage? {
        let path = NSHomeDirectory() + "/Dropbox/Summer 2015/Wallpaper/Edgeless/";
        let fileManager = NSFileManager.defaultManager()
        var allImage = try! fileManager.contentsOfDirectoryAtPath(path)
        allImage.removeFirst()
        let random = Int(arc4random_uniform(UInt32(allImage.count)))
        let url = NSURL(fileURLWithPath: path+allImage[random])
        let image = NSImage(contentsOfURL: url)
        return image
    }
    
    func setTextFieldFrame() {
        let vw = frame.width
        let vh = frame.height
    
        let h: CGFloat = 40.0
        let w = floor(vw*0.55)
        let x = floor((vw-w)/2.0)
        let y = floor((vh-h)/2.0)
        searchTextField.frame = NSMakeRect(x, y, w, h)
        var rect = NSInsetRect(searchTextField.frame, -10, -3)
        rect.origin.y += 1
        searchTextBackgroundLayer.frame = rect
    }
    
    override func controlTextDidEndEditing(obj: NSNotification) {
        if let userInfo = obj.userInfo as? Dictionary<String,AnyObject> {
            if userInfo["NSTextMovement"]?.integerValue == 0 {
                return
            }
        }
        if let t = obj.object as? NSTextField {
            generateURLByInput(t.stringValue)
        } else {
            Swift.print(#function + " error: not NSTextField can't decide URL")
        }
    }
    
    func generateURLByInput(s: String) {
        let shortCutMap = DataManager.sharedInstance.perferenceJson["short cut"][s.lowercaseString]
        if let cmd = shortCutMap["cmd"].string {
            system(cmd)
        } else if let url = shortCutMap.string {
            delegate.setWebWithURL(url)
        } else if s.hasPrefix("www.") || s.hasPrefix("http") {
            let url = s.hasPrefix("http") ? s : "http://" + s
            delegate.setWebWithURL(url)
        } else if s.hasPrefix("file://") {
            delegate.setWebWithURL(s)
        } else {
            delegate.setWebWithURL("https://www.youtube.com/results?search_query=" + s)
        }
    }
}
