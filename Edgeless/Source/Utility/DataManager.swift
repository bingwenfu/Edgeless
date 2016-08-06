//
//  AudioManager.swift
//  BlackJack
//
//  Created by Bingwen Fu on 4/5/16.
//  Copyright © 2016 Bingwen Fu. All rights reserved.
//

import Foundation
import SwiftyJSON

class DataManager : NSObject {
    
    // MARK: Singleton
    class var sharedInstance : DataManager {
        struct Static {
            static let instance : DataManager = DataManager()
        }
        return Static.instance
    }
    
    let preferencePath = "/Users/Ben/Dropbox/Edgeless/preference"
    let bookmarkPath = "/Users/Ben/Dropbox/Edgeless/bookmark"
    
    var perferenceJson: JSON = [:]
    var bookmarkJson: JSON = [:]
    
    func initialize() {
        onGlobalThread() {
            self.loadPerference()
            self.monitorFile(self.preferencePath, function: self.loadPerference)
        }
        onGlobalThread() {
            self.loadBookmark()
            self.monitorFile(self.bookmarkPath, function: self.loadBookmark)
        }
    }
    
    func loadPerference() {
        if let data = NSData(contentsOfFile: self.preferencePath) {
            onMainThread() {
                self.perferenceJson = JSON(data: data)
            }
        }
    }
    
    func loadBookmark() {
        if let data = NSData(contentsOfFile: self.bookmarkPath) {
            onMainThread() {
                self.bookmarkJson = JSON(data: data)
            }
        }
    }
    
    func addBookmark(map: [String:String]) {
        guard bookmarkJson.arrayObject != nil else {
            print(#function, "perferenceJson nil")
            return
        }
        onMainThread() {
            self.bookmarkJson.arrayObject?.append(map)
            try! self.bookmarkJson.rawString()?.writeToFile(self.bookmarkPath, atomically: true, encoding: NSUTF8StringEncoding)
        }
    }
    
    func getCurrentModificationDateOfFile(path: String) -> NSDate? {
        let fm = NSFileManager.defaultManager()
        guard fm.fileExistsAtPath(path) == true else {
            print(#function, "file does not exsit at path", path)
            return nil
        }
        guard let date = try! fm.attributesOfItemAtPath(path)[NSFileModificationDate] as? NSDate else {
            print(#function, "failed to fetch modification date for file", path)
            return nil
        }
        return date
    }

    func monitorFile(path: String, function: (Void->Void)) {
        guard let date = getCurrentModificationDateOfFile(path) else { return }
        monitorFileRec(path, function: function, lastChangeDate: date)
    }
    
    func monitorFileRec(path: String, function: (Void->Void), lastChangeDate: NSDate) {
        guard let date = getCurrentModificationDateOfFile(path) else { return }
        if date.compare(lastChangeDate) != .OrderedSame {
            print("file modified at", path)
            function()
        }
        withDelay(0.5) {
            self.monitorFileRec(path, function: function, lastChangeDate: date)
        }
    }
}

