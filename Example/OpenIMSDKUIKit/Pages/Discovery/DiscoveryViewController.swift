import Foundation
import WebKit
import UIKit

class DiscoveryViewController: UIViewController {
    
    var webView: WKWebView!
    
    lazy var activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "workbench".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        let webConfiguration = WKWebViewConfiguration();
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.frame = view.frame
        view.addSubview(webView)
        
        webView.navigationDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let discoveryURL = AccountViewModel.clientConfig?.config?.discoverPageURL
        activityIndicator.startAnimating()
        
        if discoveryURL == nil {
            AccountViewModel.getClientConfig { [self] clientConfig in
                var request: URLRequest!
                
                if let url = clientConfig?.config?.discoverPageURL {
                    request = URLRequest(url: URL(string: url)!)
                } else {
                    request = URLRequest(url: URL(string: "https://www.openim.io")!)
                }
                
                webView.load(request)
            }
        } else {
            let request = URLRequest(url: URL(string: discoverPageURL)!)
            webView.load(request)
        }
    }
}

extension DiscoveryViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }
}
