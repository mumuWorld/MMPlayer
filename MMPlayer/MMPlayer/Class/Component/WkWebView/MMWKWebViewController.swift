//
//  MMWKWebViewController.swift
//  Lumen
//
//  Created by mumu on 2019/12/30.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit
import WebKit

class MMWKWebViewController: MMBaseViewController {
    
    lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        let web = WKWebView(frame: CGRect.zero, configuration: configuration)
        web.navigationDelegate = self
        return web
    }()
    
    var loadUrl: String = "" {
        willSet {
            if newValue.count == 0 {
                MMToastView.show(message: "url有误")
                return
            }

        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        webView.frame = view.bounds
        view.addSubview(webView)
        if loadUrl.count > 0 {
            guard let url = URL(string: loadUrl) else { return }
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension MMWKWebViewController {
    class func loadUrl(url: String) -> MMWKWebViewController {
        let webVC = MMWKWebViewController()
        webVC.loadUrl = url
        return webVC
    }
}

extension MMWKWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MPPrintLog(message: "didFinish")
//        LMLoadingView.dismiss()
        guard let title = webView.title else { return }
        navigationItem.title = title
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        MPPrintLog(message: "didCommit")
//        LMLoadingView.show()
    }
}
