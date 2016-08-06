//
//  ImageManager.swift
//  WeRead
//
//  Created by Bingwen Fu on 7/19/14.
//  Copyright (c) 2014 Bingwen. All rights reserved.
//

import Cocoa

class ImageManager: NSObject {
    
    // cache map
    var memCached = Dictionary<String, NSImage>()
    var diskCached = Dictionary<String, String>()
    
    // key   - urlString of a image
    // value - a list of imageView that is waiting for the image
    var waitingPool = Dictionary<String, [NSImageView]>()
    
    // key   - imageView
    // value - the latest wanted url of image of the imageView
    var latestWantedURL = Dictionary<NSImageView, String>()
    
    // image folder, sotre disk cached image
    let imageDirPath = NSHomeDirectory() + "/Documents/Images/"
    
    typealias ImageTransformer = ((NSImage) -> NSImage)
    typealias IMCompletion = ((NSImage?) -> Void)
    
    // MARK: Singleton
    class var sharedInstance : ImageManager {
        struct Static {
            static let instance : ImageManager = ImageManager()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        getDiscCachedMap()
    }
    
    // MARK: Transformer method
    func cropTransformer(image: NSImage) -> NSImage {
        
//        let sw: CGFloat = 100
//        let sh: CGFloat = 100
//        let iw: CGFloat = image.size.width
//        let ih: CGFloat = image.size.height
//        
//        //Create the bitmap graphics context
//        UIGraphicsBeginImageContextWithOptions(CGSizeMake(sw, sh), false, 0.0);
//        let context = UIGraphicsGetCurrentContext();
//        
//        //Get the width and heights
//        let rectWidth = sw;
//        let rectHeight = sh;
//        
//        //Calculate the scale factor
//        let scaleFactorX = rectWidth/iw;
//        let scaleFactorY = rectHeight/ih;
//        
//        //Calculate the centre of the circle
//        let imageCentreX = rectWidth/2;
//        let imageCentreY = rectHeight/2;
//        
//        // Create and CLIP to a CIRCULAR Path
//        // (This could be replaced with any closed path if you want a different shaped clip)
//        let radius = rectWidth/2;
//        CGContextBeginPath(context);
//        CGContextAddArc(context, imageCentreX, imageCentreY, radius, 0, CGFloat(2*M_PI), 0);
//        CGContextClosePath(context);
//        CGContextClip(context);
//        
//        //Set the SCALE factor for the graphics context
//        //All future draw calls will be scaled by this factor
//        CGContextScaleCTM (context, scaleFactorX, scaleFactorY);
//        
//        // Draw the IMAGE
//        let myRect = CGRectMake(0, 0, iw, ih);
//        image.drawInRect(myRect)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
        
        return NSImage();
    }
    
    func standerTransformer(image: NSImage) -> NSImage {
//        let iw: CGFloat = image.size.width
//        let ih: CGFloat = image.size.height
//        let cw: CGFloat = 320 * 2
//        let ch: CGFloat = 160 * 2
//        let canvas_size = CGSizeMake(cw, ch)
//        
//        var dx: CGFloat = 0
//        var dy: CGFloat = 0
//        var dw: CGFloat = 100
//        var dh: CGFloat = 100
//        
//        if iw/ih > cw/ch {
//            dh = ch
//            dw = dh * (iw/ih)
//            dx = -(dw - cw)/2
//            dy = 0
//        } else {
//            dw = cw
//            dh = dw * (ih/iw)
//            dy = -(dh - ch)/2
//            dx = 0
//        }
//        
//        let rect = CGRectMake(dx, dy, dw, dh)
//        UIGraphicsBeginImageContext(canvas_size)
//        image.drawInRect(rect)
//        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
        return NSImage()
    }
    
    // MARK: Interface for this class
    func setImageToView(imageView: NSImageView, urlStr: String) {
        //setImageWithTransformer(urlStr, imageView: imageView, transformer: standerTransformer)
        setImageWithTransformer(urlStr, imageView: imageView, transformer: nil)
    }
    
    func setImageToViewWithCrop(imageView: NSImageView, urlStr: String) {
        //setImageWithTransformer(urlStr, imageView: imageView, transformer: cropTransformer)
    }
    
    func setImageWithTransformer(urlStr: String, imageView: NSImageView, transformer: ImageTransformer?) {
       
        // update imageView:URL map
        latestWantedURL[imageView] = urlStr
        
        // *******************************
        // try to find mem cached image
        // *******************************
        if let image = memCached[urlStr] {
            imageView.image = image
            return
        }
        
        // image is being downloaded
        if waitingPool[urlStr] != nil {
            waitingPool[urlStr]!.append(imageView)
            return
        }
        
        waitingPool[urlStr] = [imageView]
        // *******************************
        // try to find disk cached image
        // *******************************
        let result = findDiskCachedImageByURL(urlStr) { (img: NSImage?) in
            if let image = img {
                // println("get disk cached image \(urlStr)")
                self.memCached[urlStr] = image
                self.setAllWatingImageView(urlStr, image)
            }
        }
        if result { return }
        
        // *******************************
        // Download image from web
        // *******************************
        // println("prepare to download \(urlStr)")
        downloadImageByURLStr(urlStr) { (img: NSImage?) in
            if let image = img {
                var cropedImage = image
                if let crop = transformer {
                    cropedImage = crop(image)
                }
                self.memCached[urlStr] = cropedImage
                self.diskCacheImageWithURLStr(cropedImage, urlStr)
                self.setAllWatingImageView(urlStr, cropedImage)
            }
        }
    }
    
    // set the image to all the imageView that
    // is waiting for this image
    func setAllWatingImageView(urlStr: String, _ image: NSImage) {
        let imageViewCandidate = self.waitingPool[urlStr] as [NSImageView]!
        for imgView in imageViewCandidate {
            if self.latestWantedURL[imgView] == urlStr {
                onMainThread() {
                    imgView.image = image
                }
            }
        }
        self.waitingPool[urlStr] = nil
    }
    
    // MARK: Image Fecthing Method
    func findDiskCachedImageByURL(urlStr: String, _ completion: IMCompletion) -> Bool {
        // try to find the image on disk
        if urlExistOnDisk(urlStr) {
            onGlobalThread() {
                let id = self.imgIDForURL(urlStr)
                let path = self.filePathForImgID(id)
                let data  = try! NSData(contentsOfFile: path, options: .DataReadingUncached)
                let image = NSImage(data: data)
                completion(image)
            }
            return true
        }
        return false
    }
    
    func downloadImageByURLStr(urlStr: String, _ completion: IMCompletion) {
        // check the url is valid
        let url = NSURL(string: urlStr)
        if url == nil {
            print(#function + " url not valid: " + urlStr)
            return
        }
        // download
        let session = NSURLSession.sharedSession()
        session.dataTaskWithURL(url!) { (data, response, error) in
            if error != nil { print(error); return }
            if let image = NSImage(data: data!) {
                print("downloaded image \(urlStr)")
                completion(image)
            } else {
                print("Invalid image url \(urlStr)")
                return
            }
        }.resume()
    }
    
    func diskCacheImageWithURLStr(img: NSImage, _ urlStr: String) {
        // cache it to disk
        onGlobalThread() {
            let id = self.imgIDForURL(urlStr)
            let path = self.imageDirPath + id
            let data = img.TIFFRepresentation
            data!.writeToFile(path, atomically: true)
            self.diskCached[id] = id
        }
    }
    
    // MARK: Initialize disk cached map
    func getDiscCachedMap() {
        let fileManager = NSFileManager.defaultManager()
        // if Documents/Image doesn't exsits, we need create one
        if fileManager.fileExistsAtPath(imageDirPath) == false {
            try! fileManager.createDirectoryAtPath(imageDirPath, withIntermediateDirectories: true, attributes: nil)
        }
        // after making sure Documents/Image exsist we construct diskCachedMap
        let allImage = try! fileManager.contentsOfDirectoryAtPath(imageDirPath) 
        for imgID in allImage {
            diskCached[imgID] = imgID
        }
    }
    
    // MARK: Helper method
    func urlExistOnDisk(urlStr: String) -> Bool {
        let id = imgIDForURL(urlStr)
        return (diskCached[id] != nil)
    }
    
    func imgIDForURL(urlStr: String) -> String {
        return String(urlStr.hash)
    }
    
    func filePathForImgID(id: String) -> String {
        return imageDirPath + id
    }
}
