
import Foundation
import RxRelay
import RxSwift
import ProgressHUD
import OUICore

class MineViewModel {
    var currentUserRelay: BehaviorRelay<QueryUserInfo?> = .init(value: nil)

    private let _disposeBag = DisposeBag()
    
    init() {
        IMController.shared.currentUserRelay.subscribe { [weak self] info in
            if let r = info.element, let userID = r?.userID, let faceURL = r?.faceURL, let nickname = r?.nickname {
                self?.currentUserRelay.accept(QueryUserInfo(userID: userID, faceURL: faceURL, nickname: nickname))
            }
        }.disposed(by: _disposeBag)
    }
    
    func queryUserInfo() {
        if let IMUser = IMController.shared.currentUserRelay.value {
            let u = QueryUserInfo(userID: IMUser.userID, faceURL: IMUser.faceURL, nickname: IMUser.nickname)
            currentUserRelay.accept(u)
        }
        guard let userID = AccountViewModel.userID else { return }
        
        AccountViewModel.queryUserInfo(userIDList: [userID],
                                       valueHandler: { [weak self] (users: [QueryUserInfo]) in
            guard let user: QueryUserInfo = users.first else { return }
            self?.currentUserRelay.accept(user)
        }, completionHandler: {(errCode, errMsg) in
        })
    }

    func updateGender(_ gender: Gender, completion: @escaping CallBack.ErrorOptionalReturnVoid) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, gender: gender, completionHandler: completion)
    }

    func updateNickname(_ name: String, completion: @escaping CallBack.ErrorOptionalReturnVoid) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, nickname: name, completionHandler: completion)
    }

    func updateBirthday(timeStampSeconds: Int, completion: @escaping CallBack.ErrorOptionalReturnVoid) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, birth: timeStampSeconds * 1000, completionHandler: completion)
    }

    func updateFaceURL(url: String, completion: @escaping CallBack.ErrorOptionalReturnVoid) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, faceURL: url, completionHandler: completion)
    }
    
    func updateUserInfo(email: String? = nil, completion: @escaping CallBack.ErrorOptionalReturnVoid) {
        AccountViewModel.updateUserInfo(userID: IMController.shared.uid, email: email, completionHandler: completion)
    }

    func logout() {
        ProgressHUD.animate()
        NotificationCenter.default.post(name: .init("logout"), object: nil)
        IMController.shared.logout { r in
            ProgressHUD.dismiss()
        }
    }

    func uploadFile(fullPath: String, onProgress: @escaping (CGFloat) -> Void, onComplete: @escaping CallBack.ErrorOptionalReturnVoid) {
        IMController.shared.uploadFile(fullPath: fullPath, onProgress: onProgress) { [weak self] url in
            if let url = url {
                self?.updateFaceURL(url: url, completion: onComplete)
            }
        }
    }
}
