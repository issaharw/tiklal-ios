//
//  ViewController.swift
//
//  Tiklal
//
//  Created by Issahar Weiss on 13/01/2021.
//

import UIKit
import WebKit

// Feature flag: Set to true to show last position saving UI
let SHOW_LAST_POSITION_UI = false

// UserDefaults keys
private let UD_LAST_POSITION = "lastPosition"
private let UD_BOOKMARKS = "bookmarks"

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    
    var currentMajor: Int = 0
    var currentMinor: Int = 0
    var currentMajorTitle: String = ""
    var currentMinorTitle: String = ""
    
    override func loadView() {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Add message handlers for JavaScript communication
        contentController.add(self, name: "positionChanged")
        contentController.add(self, name: "webViewReady")
        contentController.add(self, name: "goToLastPosition")
        contentController.add(self, name: "addBookmark")
        contentController.add(self, name: "savePosition")
        contentController.add(self, name: "openBookmarks")
        
        configuration.userContentController = contentController
        
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webPagePreferences
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let htmlUrl = buildUrl()
        webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    func buildUrl() -> URL {
        let htmlPath = Bundle.main.path(forResource: "web/index", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
        var searchString = ""
        if UIDevice.current.userInterfaceIdiom == .pad {
            searchString = "?ipad=true"
        }
        else {
            searchString = "?ipad=false"
        }
        if UserDefaults.standard.bool(forKey: "darkMode") {
            searchString += "&darkMode=true"
        }
        if UserDefaults.standard.bool(forKey: "oldColors") {
            searchString += "&oldColors=true"
        }
        if UserDefaults.standard.integer(forKey: "fontSize") != 0 {
            let fontSize = UserDefaults.standard.integer(forKey: "fontSize")
            searchString += "&fontSize=\(fontSize)"
        }
        searchString += "&showLastPositionUI=\(SHOW_LAST_POSITION_UI)"

        return URL(string: searchString, relativeTo: htmlUrl)!
    }
    
    // MARK: - Position Management
    
    func saveCurrentPosition() {
        let position: [String: Any] = [
            "major": currentMajor,
            "minor": currentMinor,
            "majorTitle": currentMajorTitle,
            "minorTitle": currentMinorTitle,
            "timestamp": Date().timeIntervalSince1970
        ]
        if let data = try? JSONSerialization.data(withJSONObject: position),
           let json = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(json, forKey: UD_LAST_POSITION)
        }
    }
    
    func navigateToPosition(major: Int, minor: Int) {
        webView.evaluateJavaScript("navigateToPosition(\(major), \(minor))", completionHandler: nil)
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "positionChanged":
            if let body = message.body as? [String: Any] {
                currentMajor = body["major"] as? Int ?? 0
                currentMinor = body["minor"] as? Int ?? 0
                currentMajorTitle = body["majorTitle"] as? String ?? ""
                currentMinorTitle = body["minorTitle"] as? String ?? ""
                
                // Always save position
                saveCurrentPosition()
            }
            
        case "webViewReady":
            // Only restore last position if the feature is enabled
            if !SHOW_LAST_POSITION_UI { return }
            
            if let json = UserDefaults.standard.string(forKey: UD_LAST_POSITION),
               let data = json.data(using: .utf8),
               let position = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let major = position["major"] as? Int,
               let minor = position["minor"] as? Int {
                navigateToPosition(major: major, minor: minor)
            }
            
        case "goToLastPosition":
            if let json = UserDefaults.standard.string(forKey: UD_LAST_POSITION),
               let data = json.data(using: .utf8),
               let position = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let major = position["major"] as? Int,
               let minor = position["minor"] as? Int {
                navigateToPosition(major: major, minor: minor)
            } else {
                // First use - go to beginning
                navigateToPosition(major: 0, minor: 0)
            }
            
        case "addBookmark":
            addBookmark()
            
        case "savePosition":
            saveCurrentPosition()
            showToast(message: "המיקום נשמר")
            
        case "openBookmarks":
            openBookmarksScreen()
            
        default:
            break
        }
    }
    
    // MARK: - Bookmark Management
    
    func addBookmark() {
        var bookmarks = loadBookmarks()
        
        // Check if bookmark already exists
        if bookmarks.contains(where: { $0.major == currentMajor && $0.minor == currentMinor }) {
            showToast(message: "סימניה זו כבר קיימת")
            return
        }
        
        let newBookmark = Bookmark(
            major: currentMajor,
            minor: currentMinor,
            majorTitle: currentMajorTitle,
            minorTitle: currentMinorTitle
        )
        bookmarks.insert(newBookmark, at: 0)
        saveBookmarks(bookmarks)
        showToast(message: "הסימניה נוספה")
    }
    
    func loadBookmarks() -> [Bookmark] {
        guard let json = UserDefaults.standard.string(forKey: UD_BOOKMARKS),
              let data = json.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }
        return array.compactMap { Bookmark(from: $0) }
    }
    
    func saveBookmarks(_ bookmarks: [Bookmark]) {
        let array = bookmarks.map { $0.toDictionary() }
        if let data = try? JSONSerialization.data(withJSONObject: array),
           let json = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(json, forKey: UD_BOOKMARKS)
        }
    }
    
    func openBookmarksScreen() {
        let bookmarksVC = BookmarksViewController()
        bookmarksVC.currentMajor = currentMajor
        bookmarksVC.currentMinor = currentMinor
        bookmarksVC.currentMajorTitle = currentMajorTitle
        bookmarksVC.currentMinorTitle = currentMinorTitle
        bookmarksVC.showLastPositionUI = SHOW_LAST_POSITION_UI
        bookmarksVC.isDarkMode = UserDefaults.standard.bool(forKey: "darkMode")
        bookmarksVC.onNavigate = { [weak self] major, minor in
            self?.navigateToPosition(major: major, minor: minor)
        }
        bookmarksVC.modalPresentationStyle = .fullScreen
        present(bookmarksVC, animated: true)
    }
    
    func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            alert.dismiss(animated: true)
        }
    }

    // MARK: - WKNavigationDelegate & WKUIDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        guard url != nil else {
            decisionHandler(.allow)
            return
        }

        if url!.description.lowercased().contains("nosachteiman") || url!.scheme == "tel" || url!.scheme == "mailto" {
            decisionHandler(.cancel)
            UIApplication.shared.open(url!, options: [:])
        }
        else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (navigationAction.request.url != nil) {
            updateUserSettings(url: navigationAction.request.url!)
        }
        return nil
    }
    
    func updateUserSettings(url: URL) {
        let fontSize = getQueryStringParameter(url: url, param: "fontSize")
        let darkMode = getQueryStringParameter(url: url, param: "darkMode")
        let oldColors = getQueryStringParameter(url: url, param: "oldColors")
        if fontSize != nil {
            UserDefaults.standard.set(Int(fontSize!), forKey: "fontSize")
        }
        if darkMode != nil {
            UserDefaults.standard.set(Bool(darkMode!), forKey: "darkMode")
        }
        if oldColors != nil {
            UserDefaults.standard.set(Bool(oldColors!), forKey: "oldColors")
        }
    }
    
    func getQueryStringParameter(url: URL, param: String) -> String? {
      guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
      return url.queryItems?.first(where: { $0.name == param })?.value
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - Bookmark Model

struct Bookmark {
    let major: Int
    let minor: Int
    let majorTitle: String
    let minorTitle: String
    let timestamp: TimeInterval
    
    init(major: Int, minor: Int, majorTitle: String, minorTitle: String, timestamp: TimeInterval = Date().timeIntervalSince1970) {
        self.major = major
        self.minor = minor
        self.majorTitle = majorTitle
        self.minorTitle = minorTitle
        self.timestamp = timestamp
    }
    
    init?(from dict: [String: Any]) {
        guard let major = dict["major"] as? Int,
              let minor = dict["minor"] as? Int,
              let majorTitle = dict["majorTitle"] as? String,
              let minorTitle = dict["minorTitle"] as? String else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.majorTitle = majorTitle
        self.minorTitle = minorTitle
        self.timestamp = dict["timestamp"] as? TimeInterval ?? Date().timeIntervalSince1970
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "major": major,
            "minor": minor,
            "majorTitle": majorTitle,
            "minorTitle": minorTitle,
            "timestamp": timestamp
        ]
    }
}
