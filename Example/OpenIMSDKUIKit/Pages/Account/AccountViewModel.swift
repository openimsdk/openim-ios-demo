
import Alamofire
import Foundation
import OUICore
import RxSwift
import ProgressHUD

public enum UsedFor: Int {
    case register = 1
    case forgotPassword = 2
    case login = 3
}

typealias CompletionHandler = (_ errCode: Int, _ errMsg: String?) -> Void

open class AccountViewModel {

    static let API_BASE_URL = UserDefaults.standard.string(forKey: bussinessSeverAddrKey)!
    static let ADMIN_BASE_URL = UserDefaults.standard.string(forKey: adminSeverAddrKey)!

    static let IMPreLoginAccountKey = "IMPreLoginAccountKey"
    static let IMPreLoginTypeKey = "IMPreLoginTypeKey"
    static let IMUidKey = "DemoIMUidKey"
    static let IMTokenKey = "DemoIMTokenKey"
    static let bussinessTokenKey = "bussinessTokenKey"
    
    private static let LoginAPI = "/account/login"
    private static let RegisterAPI = "/account/register"
    private static let CodeAPI = "/account/code/send"
    private static let VerifyCodeAPI = "/account/code/verify"
    private static let ResetPasswordAPI = "/account/password/reset"
    private static let ChangePasswordAPI = "/account/password/change"
    private static let UpdateUserInfoAPI = "/user/update"
    private static let QueryUserInfoAPI = "/user/find/full"
    private static let SearchUserFullInfoAPI = "/user/search/full"
    private static let GetClientConfigAPI = "/client_config/get"
    
    private let _disposeBag = DisposeBag()
    
    static private func kickoff(errCode: Int) {
        if errCode == 1501 || errCode == 1503 || errCode == 1504 || errCode == 1505 || errCode == 1506 {
            NotificationCenter.default.post(name: .init("logout"), object: nil)
        }
    }


    static func ifQueryFriends() {
        
        OIMApi.queryFriendsWithCompletionHandler = { (keywords, completion: @escaping ([UserInfo]) -> Void) in
            AccountViewModel.queryFriends(content: keywords.first!, valueHandler: { users in
                let result = users.compactMap {
                    UserInfo.init(userID: $0.userID!, nickname: $0.nickname, phoneNumber: $0.phoneNumber, email: $0.email)
                }
                completion(result)
            }, completionHandler: {(errCode, errMsg) -> Void in
                kickoff(errCode: errCode)
                completion([])
            })
        }
    }

    static func ifQueryUserInfo() {
        
        OIMApi.queryUsersInfoWithCompletionHandler = { (keywords, completion: @escaping ([UserInfo]) -> Void) in
            AccountViewModel.queryUserInfo(userIDList: keywords,
                                           valueHandler: { users in
                let result = users.compactMap {
                    UserInfo(userID: $0.userID!,
                             nickname: $0.nickname,
                             phoneNumber: $0.phoneNumber,
                             email: $0.email,
                             faceURL: $0.faceURL,
                             birth: $0.birth,
                             gender: Gender(rawValue: $0.gender!),
                             landline: $0.telephone,
                             forbidden: $0.forbidden,
                             allowAddFriend: $0.allowAddFriend
                    )
                }
                completion(result)
            }, completionHandler: {(errCode, errMsg) -> Void in
                kickoff(errCode: errCode)
                completion([])
            })
        }
    }
    
    static func ifQeuryConfig() {
        OIMApi.queryConfigHandler = { (completion: (Int, [String: Any]) -> Void) in
            completion(0, AccountViewModel.clientConfig?.config?.toMap() ?? [:])
        }
    }
    
    static func loginDemo(phone: String? = nil, account: String? = nil, email: String? = nil, psw: String? = nil, verificationCode: String? = nil, areaCode: String, completionHandler: @escaping CompletionHandler) {
        let body = JsonTool.toJson(fromObject: Request(phoneNumber: phone,
                                                       account: account,
                                                       email: email,
                                                       psw: psw,
                                                       verificationCode: verificationCode,
                                                       areaCode: areaCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + LoginAPI, method: .post)
        req.httpBody = body
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        let cur = phone != nil ? phone : (email != nil ? email : account)
                        savePreLoginAccount(cur)
                        loginIM(uid: res.data!.userID, imToken: res.data!.imToken, chatToken: res.data!.chatToken, completionHandler: completionHandler)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {
                    let err = JsonTool.fromJson(result, toClass: DemoError.self)
                    completionHandler(err?.errCode ?? -1, err?.errMsg)
                }
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    private static func queryUserInfoFromChatServer(userID: String) {
        AccountViewModel.queryUserInfo(userIDList: [userID],
                                       valueHandler: { infos in
            guard let info = infos.first else { return }
            
            IMController.shared.enableRing = info.allowBeep == 2
            IMController.shared.enableVibration = info.allowVibration == 2
        }, completionHandler: { (errCode, errMsg) in
            kickoff(errCode: errCode)
        })
    }
    
    static func registerAccount(phone: String?,
                                areaCode: String?,
                                verificationCode: String,
                                password: String,
                                faceURL: String,
                                nickName: String,
                                birth: Int = Int(NSDate().timeIntervalSince1970),
                                gender: Int = 1,
                                email: String?,
                                invitationCode: String? = nil,
                                completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    RegisterRequest(
                                        phone: phone,
                                        areaCode: areaCode,
                                        verificationCode: verificationCode,
                                        password: password,
                                        faceURL: faceURL,
                                        nickName: nickName,
                                        birth: birth,
                                        gender: gender,
                                        email: email,
                                        invitationCode: invitationCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + RegisterAPI, method: .post)
        req.httpBody = body
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString() { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        saveUser(uid: res.data?.userID, imToken: res.data?.imToken, chatToken: res.data?.chatToken)
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }

    static func requestCode(phone: String? = nil, areaCode: String? = nil, email: String? = nil, invaitationCode: String? = nil, useFor: UsedFor, completionHandler: @escaping CompletionHandler) {
        let body = JsonTool.toJson(fromObject:
                                    CodeRequest(
                                        phone: phone,
                                        areaCode: areaCode,
                                        email: email,
                                        usedFor: useFor.rawValue,
                                        invaitationCode: invaitationCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + CodeAPI, method: .post)
        req.httpBody = body
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {
                }
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }

    static func verifyCode(phone: String?, areaCode: String?, email: String? = nil, useFor: UsedFor, verificationCode: String, completionHandler: @escaping CompletionHandler) {
        let body = JsonTool.toJson(fromObject:
                                    CodeRequest(
                                        phone: phone,
                                        areaCode: areaCode,
                                        email: email,
                                        usedFor: useFor.rawValue,
                                        verificationCode: verificationCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + VerifyCodeAPI, method: .post)
        req.httpBody = body
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    static func resetPassword(phone: String?,
                              areaCode: String?,
                              email: String?,
                              verificationCode: String,
                              password: String,
                              completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    Request(
                                        phoneNumber: phone,
                                        email: email,
                                        psw: password,
                                        verificationCode: verificationCode,
                                        areaCode: areaCode)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + ResetPasswordAPI, method: .post)
        req.httpBody = body
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    static func changePassword(userID: String, current password1: String, to password2: String, completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    ChangePasswordRequest(
                                        userID: userID,
                                        currentPassword: password1,
                                        newPassword: password2)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + ChangePasswordAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UserEntity>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        kickoff(errCode: res.errCode)
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }

    static func updateUserInfo(userID: String,
                               account: String? = nil,
                               areaCode: String? = nil,
                               phone: String? = nil,
                               email: String? = nil,
                               nickname: String? = nil,
                               faceURL: String? = nil,
                               gender: Gender? = nil,
                               birth: Int? = nil,
                               level: Int? = nil,
                               allowAddFriend: Int? = nil,
                               allowBeep: Int? = nil,
                               allowVibration: Int? = nil,
                               completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    UpdateUserInfoRequest(userID: userID,
                                                          phone: phone,
                                                          faceURL: faceURL,
                                                          nickname: nickname,
                                                          birth: birth,
                                                          gender: gender,
                                                          account: account,
                                                          level: level,
                                                          email: email,
                                                          allowAddFriend: allowAddFriend,
                                                          allowBeep: allowBeep,
                                                          allowVibration: allowVibration)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + UpdateUserInfoAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<UpdateUserInfoRequest>.self) {
                    if res.errCode == 0 {
                        completionHandler(res.errCode, nil)
                    } else {
                        kickoff(errCode: res.errCode)
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {}
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }

    static func queryUserInfo(pageNumber: Int = 1,
                              showNumber: Int = 10,
                              userIDList: [String],
                              valueHandler: @escaping ([QueryUserInfo]) -> Void,
                              completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    QueryUserInfoRequest(userIDList: userIDList)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + QueryUserInfoAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString(encoding: .utf8) { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<QueryUserInfoData>.self) {
                    if res.errCode == 0 {
                        valueHandler(res.data!.users)
                    } else {
                        kickoff(errCode: res.errCode)
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {
                    completionHandler(-1, result)
                }
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }

    static func queryFriends(pageNumber: Int = 1,
                             showNumber: Int = 100,
                             content: String,
                             valueHandler: @escaping ([QueryUserInfo]) -> Void,
                             completionHandler: @escaping CompletionHandler)
    {
        let body = JsonTool.toJson(fromObject:
                                    QueryFriendsRequest(keyword: content,
                                                        pageNumber: pageNumber,
                                                        showNumber: showNumber)).data(using: .utf8)
        
        var req = try! URLRequest(url: API_BASE_URL + SearchUserFullInfoAPI, method: .post)
        req.httpBody = body
        req.addValue(UserDefaults.standard.string(forKey: bussinessTokenKey)!, forHTTPHeaderField: "token")
        req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
        
        Alamofire.request(req).responseString(encoding: .utf8) { (response: DataResponse<String>) in
            switch response.result {
            case .success(let result):
                if let res = JsonTool.fromJson(result, toClass: Response<QueryUserInfoData>.self) {
                    if res.errCode == 0 {
                        valueHandler(res.data!.users)
                    } else {
                        kickoff(errCode: res.errCode)
                        completionHandler(res.errCode, res.errMsg)
                    }
                } else {
                    completionHandler(-1, nil)
                }
            case .failure(let err):
                completionHandler(-1, err.localizedDescription)
            }
        }
    }
    
    static func loginIM(uid: String, imToken: String, chatToken: String, completionHandler: @escaping CompletionHandler) {
        
        IMController.shared.login(uid: uid, token: imToken) { resp in
            print("login onSuccess \(String(describing: resp))")
            completionHandler(0, nil)
            
            ifQueryFriends()
            ifQueryUserInfo()
            ifQeuryConfig()
            saveUser(uid: uid, imToken: imToken, chatToken: chatToken)
            queryUserInfoFromChatServer(userID: uid)
        } onFail: { (code: Int, msg: String?) in
            let reason = "login onFail: code \(code), reason \(String(describing: msg))"
            completionHandler(code, reason)
            kickoff(errCode: code)
            saveUser(uid: nil, imToken: nil, chatToken: nil)
        }
    }
    
    static func saveUser(uid: String?, imToken: String?, chatToken: String?) {
        UserDefaults.standard.set(uid, forKey: IMUidKey)
        UserDefaults.standard.set(imToken, forKey: IMTokenKey)
        UserDefaults.standard.set(chatToken, forKey: bussinessTokenKey)
        UserDefaults.standard.synchronize()
        
        IMController.shared.setup(businessServer: UserDefaults.standard.string(forKey: bussinessSeverAddrKey)!, businessToken: chatToken)
    }
    
    static func savePreLoginAccount(_ account: String?) {
        UserDefaults.standard.set(account, forKey: IMPreLoginAccountKey)
        UserDefaults.standard.synchronize()
    }
    
    static var perLoginAccount: String? {
        return UserDefaults.standard.string(forKey: IMPreLoginAccountKey)
    }
    
    static var userID: String? {
        return UserDefaults.standard.string(forKey: IMUidKey)
    }
    
    static var baseUser: UserEntity {
        return UserEntity(userID: UserDefaults.standard.string(forKey: IMUidKey) ?? "",
                          imToken: UserDefaults.standard.string(forKey: IMTokenKey) ?? "",
                          chatToken: UserDefaults.standard.string(forKey: bussinessTokenKey) ?? "",
                          expiredTime: nil)
    }
    
    
    static func getClientConfig(completion: ((ClientConfigData?) -> Void)? = nil) {
        let configData = ClientConfigData()
        let config = ClientConfigData.Config()
        config.discoverPageURL = discoverPageURL
        config.allowSendMsgNotFriend = allowSendMsgNotFriend
        
        completion?(configData)
        /*
         let body = try! JSONSerialization.data(withJSONObject: ["operationID": UUID().uuidString], options: .prettyPrinted)
         
         var req = try! URLRequest(url: ADMIN_BASE_URL + GetClientConfigAPI, method: .post)
         req.httpBody = body
         req.addValue(UUID().uuidString, forHTTPHeaderField: "operationID")
         
         Alamofire.request(req).responseString(encoding: .utf8) { (response: DataResponse<String>) in
         switch response.result {
         case .success(let result):
         if let res = JsonTool.fromJson(result, toClass: Response<ClientConfigData>.self) {
         if res.errCode == 0 {
         clientConfig = res.data
         completion?(clientConfig)
         } else {
         completion?(nil)
         }
         } else {
         completion?(nil)
         }
         case .failure(_):
         completion?(nil)
         }
         }
         */
    }

    static var clientConfig: ClientConfigData?
    
    static public func checkVersion() async -> (url: String, version: String)? {
        
        let param = ["_api_key": "",
                     "appKey": ""]
        
        guard let url = URL(string: "https://www.pgyer.com/apiv2/app/check") else { return nil }
        
        return await withCheckedContinuation { continuation in
            Alamofire.request(url, method: .post, parameters: param, headers: ["contentType": "application/x-www-form-urlencoded"]).responseJSON { response in
                
                switch response.result {
                case .success(let data):
                    if let json = data as? [String: Any], let data2 = json["data"] as? [String: Any], let url = data2["appURl"] as? String {
                        let version = "\((data2["buildVersion"] as! String)) + \((data2["buildVersionNo"] as! String))"
                        
                        continuation.resume(returning: (url: url, version: version))
                    } else {
                        continuation.resume(returning: nil)
                    }
                case .failure(_):
                    
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}


class Request: Encodable {
    private let areaCode: String?
    private let phoneNumber: String?
    private let password: String
    private let verifyCode: String?
    private let platform: Int = 1
    private let account: String?
    private let email: String?
    
    init(phoneNumber: String? = nil, account: String? = nil, email: String? = nil, psw: String? = nil, verificationCode: String? = nil, areaCode: String? = nil) {
        self.phoneNumber = phoneNumber
        self.email = email
        self.account = account
        self.password = psw?.md5() ?? ""
        self.areaCode = areaCode
        self.verifyCode = verificationCode
    }
}

class Response<T: Decodable>: Decodable {
    var data: T? = nil
    var errCode: Int = 0
    var errMsg: String? = nil
    var errDlt: String?
}

struct UserEntity: Decodable {
    let userID: String
    let imToken: String
    let chatToken: String
    let expiredTime: Int?
}

class RegisterRequest: Encodable {
    private var verifyCode: String?
    private let platform: Int = 1
    private let user: UpdateUserInfoRequest
    private let invitationCode: String?
    private let deviceID = UUID().uuidString
    private let autoLogin = true
    
    init(phone: String?, areaCode: String?, verificationCode: String?, password: String?, faceURL: String?, nickName: String?, birth: Int?, gender: Int?, email: String? = nil, invitationCode: String?) {
        self.user = UpdateUserInfoRequest(phone: phone, password: password, areaCode: areaCode, nickname: nickName, email: email)
        self.verifyCode = verificationCode
        self.invitationCode = invitationCode
    }
}

class CodeRequest: Encodable {
    private let areaCode: String?
    private let phoneNumber: String?
    private let email: String?
    private let usedFor: Int
    private let verifyCode: String?
    private let invaitationCode: String?
    private let platform: Int = 1
    
    init(phone: String? = nil, areaCode: String? = nil, email: String? = nil, usedFor: Int, invaitationCode: String? = nil, verificationCode: String? = nil) {
        assert(phone != nil || email != nil, "phone or email is nil")
        self.phoneNumber = phone
        self.email = email
        self.areaCode = areaCode
        self.usedFor = usedFor
        self.verifyCode = verificationCode
        self.invaitationCode = invaitationCode
    }
}

class QueryUserInfoRequest: Encodable {
    private let userIDs: [String]
    
    init(pageNumber: Int = 1, showNumber: Int = 10, userIDList: [String]) {
        self.userIDs = userIDList
    }
}

class QueryUserInfoData: Decodable {
    let users: [QueryUserInfo]
    let totalNumber: Int?
}

class QueryUserInfo: UpdateUserInfoRequest {}

class UpdateUserInfoRequest: Codable {
    let userID: String?
    let account: String?
    let password: String?
    let level: Int?
    var faceURL: String?
    var nickname: String?
    let areaCode: String?
    let phoneNumber: String?
    let telephone: String?
    let hireDate: String?
    private var platform: Int? = 1
    var birth: Int?
    var gender: Int?
    var email: String?
    let englishName: String?
    let forbidden: Int?
    let allowAddFriend: Int?
    let allowBeep: Int?
    let allowVibration: Int?
    
    init(userID: String? = nil,
         phone: String? = nil,
         password: String? = nil,
         telephone: String? = nil,
         areaCode: String? = nil,
         faceURL: String? = nil,
         nickname: String? = nil,
         englishName: String? = nil,
         birth: Int? = nil,
         gender: Gender? = nil,
         account: String? = nil,
         level: Int? = nil,
         email: String? = nil,
         hireDate: String? = nil,
         allowAddFriend: Int? = nil,
         allowBeep: Int? = nil,
         allowVibration: Int? = nil,
         forbidden: Int? = nil)
    {
        self.areaCode = areaCode
        self.telephone = telephone
        self.password = password?.md5()
        self.phoneNumber = phone
        self.faceURL = faceURL
        self.nickname = nickname
        self.englishName = englishName
        self.birth = birth
        self.gender = gender?.rawValue
        self.email = email
        self.account = account
        self.level = level
        self.userID = userID
        self.hireDate = hireDate
        self.allowAddFriend = allowAddFriend
        self.allowBeep = allowBeep
        self.allowVibration = allowVibration
        self.forbidden = forbidden
    }
}

class ChangePasswordRequest: Encodable {
    private let userID: String
    private let currentPassword: String
    private let newPassword: String
    
    init(userID: String, currentPassword: String, newPassword: String) {
        self.userID = userID
        self.currentPassword = currentPassword.md5
        self.newPassword = newPassword.md5
    }
}

class QueryFriendsRequest: Encodable {
    private let pagination: Pagination
    private let keyword: String
    private let platform: Int = 1
    
    init(keyword: String, pageNumber: Int = 1, showNumber: Int = 100) {
        self.keyword = keyword
        self.pagination = Pagination(pageNumber: pageNumber, showNumber: showNumber)
    }
}

class Pagination: Encodable {
    private let pageNumber: Int
    private let showNumber: Int
    
    init(pageNumber: Int, showNumber: Int) {
        self.pageNumber = pageNumber
        self.showNumber = showNumber
    }
}

class ClientConfigData: Codable {
    
    class Config: Codable {
        var discoverPageURL: String?
        var ordinaryUserAddFriend: String?
        var bossUserID: String?
        var adminURL: String?
        var allowSendMsgNotFriend: String?
        var needInvitationCodeRegister: String?
        var robots: [String]?
        
        func toMap() -> [String: Any] {
            return JsonTool.toMap(fromObject: self)
        }
    }
    
    var config: Config?
}

struct DemoError: Error, Decodable {
    let errCode: Int
    let errMsg: String?
    
    var localizedDescription: String {
        let msg: String = errMsg ?? "no message"
        return "code: \(errCode), msg: \(msg)"
    }
}
