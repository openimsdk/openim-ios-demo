

























import Alamofire
import Foundation

public enum NetworkActivityLoggerLevel {

    case off

    case debug

    case info

    case warn

    case error

    case fatal
}

public class NetworkActivityLogger {


    public static let shared = NetworkActivityLogger()

    public var level: NetworkActivityLoggerLevel

    public var filterPredicate: NSPredicate?
    
    private var startDates: [URLSessionTask: Date]

    
    init() {
        level = .info
        startDates = [URLSessionTask: Date]()
    }
    
    deinit {
        stopLogging()
    }


    public func startLogging() {
        stopLogging()
        
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.networkRequestDidStart(notification:)),
            name: Notification.Name.Task.DidResume,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(NetworkActivityLogger.networkRequestDidComplete(notification:)),
            name: Notification.Name.Task.DidComplete,
            object: nil
        )
    }

    public func stopLogging() {
        NotificationCenter.default.removeObserver(self)
    }

    
    @objc private func networkRequestDidStart(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let task = userInfo[Notification.Key.Task] as? URLSessionTask,
            let request = task.originalRequest,
            let httpMethod = request.httpMethod,
            let requestURL = request.url
            else {
                return
        }
        
        if let filterPredicate = filterPredicate, filterPredicate.evaluate(with: request) {
            return
        }
        
        if startDates[task] != nil {
            startDates[task] = Date()
        }
        
        switch level {
        case .debug:
            logDivider()
            
            print("\(httpMethod) '\(requestURL.absoluteString)':")
            
            if let httpHeadersFields = request.allHTTPHeaderFields {
                logHeaders(headers: httpHeadersFields)
            }
            
            if let httpBody = request.httpBody, let httpBodyString = String(data: httpBody, encoding: .utf8) {
                print(httpBodyString)
            }
        case .info:
            logDivider()
            
            print("\(httpMethod) '\(requestURL.absoluteString)'")
        default:
            break
        }
    }
    
    @objc private func networkRequestDidComplete(notification: Notification) {
        guard let sessionDelegate = notification.object as? SessionDelegate,
            let userInfo = notification.userInfo,
            let task = userInfo[Notification.Key.Task] as? URLSessionTask,
            let request = task.originalRequest,
            let httpMethod = request.httpMethod,
            let requestURL = request.url
            else {
                return
        }
        
        if let filterPredicate = filterPredicate, filterPredicate.evaluate(with: request) {
            return
        }
        
        var elapsedTime: TimeInterval = 0.0
        
        if let startDate = startDates[task] {
            elapsedTime = Date().timeIntervalSince(startDate)
            if startDates[task] != nil {
                startDates[task] = nil
            }
        }
        
        if let error = task.error {
            switch level {
            case .debug, .info, .warn, .error:
                logDivider()
                
                print("[Error] \(httpMethod) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:")
                print(error)
            default:
                break
            }
        } else {
            guard let response = task.response as? HTTPURLResponse else {
                return
            }
            
            switch level {
            case .debug:
                logDivider()
                
                print("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]:")
                
                logHeaders(headers: response.allHeaderFields)
                
                guard let data = sessionDelegate[task]?.delegate.data else { break }
                    
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                    let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    
                    if let prettyString = String(data: prettyData, encoding: .utf8) {
                        print(prettyString)
                    }
                } catch {
                    if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                        print(string)
                    }
                }
            case .info:
                logDivider()
                
                print("\(String(response.statusCode)) '\(requestURL.absoluteString)' [\(String(format: "%.04f", elapsedTime)) s]")
            default:
                break
            }
        }
    }
}

private extension NetworkActivityLogger {
    func logDivider() {
        print("---------------------")
    }
    
    func logHeaders(headers: [AnyHashable : Any]) {
        print("Headers: [")
        for (key, value) in headers {
            print("  \(key) : \(value)")
        }
        print("]")
    }
}
