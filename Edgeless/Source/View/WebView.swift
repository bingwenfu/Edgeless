//
//  WebView.swift
//
//
//  Created by Bingwen Fu on 12/11/15.
//
//

import Cocoa
import WebKit
import KVOController

class WebView: WKWebView, WKUIDelegate, WKNavigationDelegate {
    
    var delegate: WebWindow!
    
    init(frame: NSRect) {
        let config = WKWebViewConfiguration()
        config.preferences.plugInsEnabled = true
        super.init(frame: frame, configuration: config)
        UIDelegate = self
        navigationDelegate = self
        allowsBackForwardNavigationGestures = true
        allowsMagnification = true
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(WebView.checkURL), userInfo: nil, repeats: true)
    }
    
    let progresssView = NJKWebViewProgressView(frame:NSZeroRect)
    func prepareWebLoadingIndicator(urlString: String) {
        if urlString != "" {
            progresssView.frame = NSMakeRect(0, 0, self.frame.width, 5.0)
            progresssView.setProgress(0.01, animated: false)
        } else {
            progresssView.frame = NSMakeRect(0, 0, self.frame.width, 5.0)
            progresssView.setProgress(0.01, animated: false)
        }
        
        if progresssView.superview == nil {
            self.addSubview(progresssView)
            
            self.KVOController = FBKVOController(observer: self)
            self.KVOController.observe(self, keyPath: "estimatedProgress", options: .New) { (a, b, c) in
                let progress = c[NSKeyValueChangeNewKey] as! Float
                self.progresssView.setProgress(progress, animated: true)
            }
        }
    }
    
    func loadURL(urlStr: String) {
        if let noSpaceUrl = urlStr.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
            if let url = NSURL(string: noSpaceUrl) {
                let request = NSURLRequest(URL: url)
                //self.prepareWebLoadingIndicator(noSpaceUrl)
                self.loadRequest(request)
            }
        }
    }
    
    let fbnURL = [
        "https://www.youtube.com/": true,
        "https://www.youtube.com/user/theyearinreview": true,
        "http://news.baidu.com/": true,
        ]
    
    func checkURL() {
        guard let url = URL?.relativeString else { return }
        if fbnURL[url] == true {
            delegate.setToSearchView()
        }
    }
    
    var watchBaseURL = ""
    func extractFullScreenYoutubeVideo() {
        guard let url = URL?.relativeString else { return }
        guard url.hasPrefix("https://www.youtube.com/watch?v=") else { loadURL(watchBaseURL); return }
        
        watchBaseURL = url
        let str = "<body style=\"margin:0px; padding:0px; overflow:hidden\"><iframe width=100% height=100% src=\"https://www.youtube.com/embed/@@@?autoplay=1\" frameborder=\"0\"></iframe></body>"
        let id = url.stringByReplacingOccurrencesOfString("https://www.youtube.com/watch?v=", withString: "")
        let html = str.stringByReplacingOccurrencesOfString("@@@", withString: id)
        loadHTMLString(html, baseURL: nil)
        Swift.print(watchBaseURL, id, html)
    }
    
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.loadRequest(navigationAction.request)
        }
        return nil;
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation) {
        Swift.print("Finished navigating to " + webView.URL!.relativeString!)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        Swift.print(error, #function)
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        Swift.print(error, #function)
    }
}
