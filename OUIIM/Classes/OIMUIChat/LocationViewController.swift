
import OUICore
import WebKit
import CoreLocation
import ProgressHUD

public struct LocationPoint: Encodable {
    var title: String?
    var desc: String!
    var longitude: Double = 0
    var latitude: Double = 0
}

typealias LocationCallback = (_ point: LocationPoint) -> Void

fileprivate let webKey = "75a0da9ec836d573102999e99abf4650"
fileprivate let webServerKey = "835638634b8f9b4bba386eeec94aa7df"
fileprivate let host = "http://location.rentsoft.cn"

class LocationViewController: UIViewController, WKScriptMessageHandler {
    
    public class func getStaticMapURL(longitude: Double, latitude: Double) -> URL {
        let url = "https://restapi.amap.com/v3/staticmap?location=\(longitude),\(latitude)&zoom=13&size=200*200&markers=mid,,A:\(longitude),\(latitude)&key=\(webServerKey)"
        
        return URL(string: url)!
    }
    
    private let locationManager = CLLocationManager()
    
    public init(_ point: LocationPoint? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        locationPoint = point
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var callback: LocationCallback?
    
    func onSendLocation(cb: @escaping LocationCallback) {
        callback = cb
    }
        
    lazy var sendButton: UIBarButtonItem = {
        let v = UIBarButtonItem(title: "determine".innerLocalized(), style: .done, target: self, action: #selector(onSend))

        return v
    }()
    
    lazy var mapWebView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "getLocaltion")
        
        let v = WKWebView.init(frame: .zero, configuration: config)
        v.uiDelegate = self
        v.navigationDelegate = self
        
        return v
    }()
    
    var locationPoint: LocationPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()


        view.addSubview(mapWebView)
        mapWebView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        locationManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationManager.requestWhenInUseAuthorization()
    }
    
    @objc private func onSend() {
        if let desc = locationPoint?.desc, !desc.isEmpty {
            callback?(locationPoint!)
            navigationController?.popViewController(animated: true)
        } else {
            presentAlert(title: "plsSelectLocation".innerLocalized(), cancelTitle: "determine".innerLocalized())
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "getLocaltion", let messageBody = message.body as? String {

            print("Received message from JavaScript: \(messageBody)")
            let data = messageBody.data(using: .utf8)!
            
            if let map = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                do {
                    locationPoint = LocationPoint()
                    
                    let name = map["name"] as? String
                    let address = map["address"]  as! String
                    let locationStr = map["location"] as! String
                    let location = locationStr.components(separatedBy: ",")
                    let longitude = Double(location[0])!
                    let latitude = Double(location[1])!
                    
                    let descMap = ["name": name, "addr": address, "url": Self.getStaticMapURL(longitude: longitude, latitude: latitude).absoluteString] as [String : Any]
                    if let descJson = try? JSONSerialization.data(withJSONObject: descMap) {
                        let desc = String(data: descJson, encoding: .utf8)
                        locationPoint?.desc = desc
                    }
                    
                    locationPoint?.title = name ?? address
                    locationPoint?.longitude = longitude
                    locationPoint?.latitude = latitude
                    
                    onSend()
                } catch (let e) {
                    
                }
            }
        }
    }
    
    func loadHTML() {
        var path = "\(host)?key=\(webKey)&serverKey=\(webServerKey)#/"
        
        if let locationPoint {
            path = "\(host)?key=\(webKey)&serverKey=\(webServerKey)&location=\(locationPoint.longitude),\(locationPoint.latitude)#/"
        }
        if let url = URL(string: path) {
            let request = URLRequest(url: url)
            mapWebView.load(request)
        }
    }
}

extension LocationViewController : WKUIDelegate, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let request = navigationAction.request
        let url = navigationAction.request.url?.absoluteString 
        let hostname = request.url?.host?.lowercased();
        
        print("===url:\(url)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let respose = navigationResponse.response
        print("\(#function): \(respose)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("\(#function): \(challenge)")
        completionHandler(.performDefaultHandling, nil)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("\(#function): \(navigation)")

        ProgressHUD.animate()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        ProgressHUD.dismiss()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("\(#function): error:\(error)")
        ProgressHUD.dismiss()
    }
        
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("\(#function): error:\(error)")
        ProgressHUD.dismiss()
    }
}

extension LocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if locationPoint == nil {
                locationPoint = LocationPoint()

                
                if let location = manager.location {
                    locationPoint?.latitude = location.coordinate.latitude
                    locationPoint?.longitude = location.coordinate.longitude
                }
            }
            
            loadHTML()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location:\(locations.first)")
    }
}
