
import OUICore
import RxSwift
import RxRelay

class SettingViewModel {
    
    let setRingRelay: BehaviorRelay<Bool> = .init(value: true)
    let setVibrationRelay: BehaviorRelay<Bool> = .init(value: true)
    let setForbbidenAddFriendRelay: BehaviorRelay<Bool> = .init(value: false)
    
    let notDisturbRelay: BehaviorRelay<Bool> = .init(value: false)
    let blockedList: BehaviorRelay<[BlackInfo]> = .init(value: [])
    
    func getSettingInfo() {
        IMController.shared.getSelfInfo {[weak self] user in
            self?.notDisturbRelay.accept(user?.globalRecvMsgOpt == .receive)
        }
        
        guard let userID = IMController.shared.currentUserRelay.value?.userID else { return }
        
        AccountViewModel.queryUserInfo(userIDList: [userID],
                                       valueHandler: { [weak self] infos in
            guard let info = infos.first else { return }
            self?.setRingRelay.accept(info.allowBeep == 2)
            self?.setVibrationRelay.accept(info.allowVibration == 2)
            self?.setForbbidenAddFriendRelay.accept(info.allowAddFriend == 2)
        }, completionHandler: { (errCode, errMsg) in
            
        })
    }
    
    func getBlockedList() {
        IMController.shared.getBlackList { [weak self] (users: [BlackInfo]) in
            self?.blockedList.accept(users)
        }
    }
    
    func removeFromBlockedList(uid: String, onSuccess: @escaping CallBack.StringOptionalReturnVoid) {
        IMController.shared.removeFromBlackList(uid: uid) {[weak self] _ in
            self?.getBlockedList()
            onSuccess("")
        }
    }
    
    func toggleNotDisturbStatus() {
        let s : ReceiveMessageOpt = !self.notDisturbRelay.value ? .receive : .notNotify
        IMController.shared.setGlobalRecvMessageOpt(op: s) { [weak self] r in
            guard let sself = self else { return }
            sself.notDisturbRelay.accept(!sself.notDisturbRelay.value)
        }
    }
    
    func toggleRing() {

        AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!, allowBeep: self.setRingRelay.value ? 1 : 2) { [weak self] (errCode, errMsg) in
            guard let sself = self else { return }
            sself.setRingRelay.accept(!sself.setRingRelay.value)
            IMController.shared.enableRing = sself.setRingRelay.value
        }
    }
    
    func toggleVibrationRelay()  {

        AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!, allowVibration: self.setVibrationRelay.value ? 1 : 2) { [weak self] (errCode, errMsg) in
            guard let sself = self else { return }
            sself.setVibrationRelay.accept(!sself.setVibrationRelay.value)
            IMController.shared.enableVibration = sself.setVibrationRelay.value
        }
    }
    
    func toggleForbbidenAddFriendRelay()  {

        AccountViewModel.updateUserInfo(userID: AccountViewModel.userID!, allowAddFriend: self.setForbbidenAddFriendRelay.value ? 1 : 2) { [weak self] (errCode, errMsg) in
            guard let sself = self else { return }
            sself.setForbbidenAddFriendRelay.accept(!sself.setForbbidenAddFriendRelay.value)
        }
    }
    
    func clearHistory(onSuccess: @escaping CallBack.StringOptionalReturnVoid)  {
        IMController.shared.deleteAllMsgFromLocalAndSvr(onSuccess: onSuccess)
    }
    
    func changePassword(current password1: String, to password2: String, completion: @escaping CompletionHandler) {
        AccountViewModel.changePassword(userID: IMController.shared.uid, current: password1, to: password2, completionHandler: completion)
    }
}
