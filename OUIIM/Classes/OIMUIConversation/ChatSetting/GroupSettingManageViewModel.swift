
import OUICore
import RxCocoa
import RxSwift

class GroupSettingManageViewModel {
    private(set) var groupInfo: GroupInfo
    
    private var groupID: String!
    
    var groupInfoRelay: BehaviorRelay<GroupInfo?> = .init(value: nil)
    
    private(set) var allMembers: [String] = []
    private let disposeBag = DisposeBag()

    init(groupInfo: GroupInfo) {
        self.groupInfo = groupInfo
        self.groupID = groupInfo.groupID
        
        IMController.shared.groupInfoChangedSubject.subscribe(onNext: { [weak self] info in
            if info.groupID == self?.groupInfoRelay.value?.groupID {
                self?.groupInfoRelay.accept(info)
            }
        }).disposed(by: disposeBag)
    }
    
    func initialStatus() {
        groupInfoRelay.accept(groupInfo)
    }
    
    func transferOwner(to uid: String, onSuccess: @escaping CallBack.VoidReturnVoid) {
        IMController.shared.transferOwner(groupId: groupID, to: uid) { r in
            onSuccess()
        }
    }
}
