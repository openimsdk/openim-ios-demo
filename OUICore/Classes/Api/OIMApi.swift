import Foundation
import Alamofire

public typealias CompletionHandler<T: Any> = (Int, T) -> Void
public typealias QueryInfoHandler = ((_ keywords: [String], _ completion: @escaping (([UserInfo]) -> Void)) -> Void)
public typealias QueryDataHandler<T: Any> = ((_ completion: @escaping CompletionHandler<T>) -> Void)

public class OIMApi {
    
    private static let userOnlineStatus = "/user/get_users_online_status"

    public static func queryOnlineStatus(userID: String, completionHandler: @escaping ((_ status: [String: String]) -> Void)) {
        let body = JsonTool.toJson(fromObject: OnlineStatusRequest.init(userIDs: [userID])).data(using: .utf8)
        
        var req = try! URLRequest.init(url: IMController.shared.sdkAPIAdrr + userOnlineStatus, method: .post)
        req.httpBody = body
        req.addValue(IMController.shared.token, forHTTPHeaderField: "token")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<[OnlineStatus]>.self) {
                    if res.errCode == 0 {
                        completionHandler(paraseOnlineStatus(res.data))
                    } else {
                    }
                }
            case .failure(_):
                break
            }
        }
    }
    
    private static func paraseOnlineStatus(_ status: [OnlineStatus]) -> [String: String] {
        
        var statusDesc: [String: String] = [:]
        
        status.forEach({ onlineStatus in
            if (onlineStatus.status == "online") {







                if let detail = onlineStatus.detailPlatformStatus {
                    var pList: [String] = [];
                    for (index, platform) in detail.enumerated() {
                        if (platform.platform == "Android" || platform.platform == "IOS") {
                            pList.append("手机".innerLocalized())
                        } else if (platform.platform == "Windows") {
                            pList.append("PC".innerLocalized())
                        } else if (platform.platform == "Web") {
                            pList.append("Web".innerLocalized())
                        } else if (platform.platform == "MiniWeb") {
                            pList.append("Mini".innerLocalized())
                        } else {
                            statusDesc[onlineStatus.userID] = "在线".innerLocalized()
                        }
                    }
                    statusDesc[onlineStatus.userID] = "\(pList.joined(separator: "/"))在线"
                }
            } else {
                statusDesc[onlineStatus.userID] = "离线"
            }
        })
        
        return statusDesc
    }
    
    public static func post<T: Decodable>(url: String, body: Data?, token: String? = nil, completionHandler: @escaping CompletionHandler<T?>) {
        var req = try! URLRequest.init(url: url, method: .post)
        req.addValue(token ?? IMController.shared.token, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        if body != nil {
            req.httpBody = body!
        }
        DispatchQueue.global().async {
            Alamofire.request(req).responseString(encoding: .utf8) { (response: DataResponse<String>) in
                switch response.result {
                case .success(let result):
                    let res = JsonTool.fromJson(result, toClass: Response<T>.self)
                    DispatchQueue.main.async {
                        if let res = res, res.errCode == 0 {
                            completionHandler(res.errCode, res.data)
                        } else {
                            completionHandler(res?.errCode ?? -1, nil)
                        }
                    }
                case .failure(_):
                    break
                }
            }
        }
    }
    
    public static func postNoDataKey(url: String, body: Data?, token: String? = nil, completionHandler: @escaping CompletionHandler<String?>) {
        var req = try! URLRequest.init(url: url, method: .post)
        req.addValue(token ?? IMController.shared.token, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        if body != nil {
            req.httpBody = body!
        }
        DispatchQueue.global().async {
            Alamofire.request(req).responseString(encoding: .utf8) { (response: DataResponse<String>) in
                switch response.result {
                case .success(let result):
                    let res = JsonTool.fromJson(result, toClass: NoDataKeyResponse.self)
                    DispatchQueue.main.async {
                        if let res = res, res.errCode == 0 {
                            completionHandler(res.errCode, nil)
                        } else {
                            completionHandler(res?.errCode ?? -1, res?.errMsg)
                        }
                    }
                case .failure(_):
                    break
                }
            }
        }
    }

    public static var queryFriendsWithCompletionHandler: QueryInfoHandler?
    public static var queryUsersInfoWithCompletionHandler: QueryInfoHandler?
    public static var queryConfigHandler: QueryDataHandler<[String: Any]>?
    public static var rotationHandler: ((UIInterfaceOrientationMask) -> Void)?
}

extension OIMApi {
    class OnlineStatusRequest: Encodable {
        private let userIDList: [String]
        private let platform: Int = 1
        private let operationID = UUID.init().uuidString
        init(userIDs: [String]) {
            self.userIDList = userIDs
        }
    }
    
    struct OnlineStatus: Decodable {
        let userID: String
        let status: String
        let detailPlatformStatus: [DetailPlatformStatus]?
    }
    
    struct DetailPlatformStatus: Decodable {
        let platform: String
        let status: String
    }
    
    public class Response<T: Decodable>: Decodable {
        public var data: T
        public var errCode: Int = 0
        public var errMsg: String?
        public var errDlt: String?
    }
    
    public class NoDataKeyResponse: Decodable {
        public var errCode: Int = 0
        public var errMsg: String?
        public var errDlt: String?
    }
}
