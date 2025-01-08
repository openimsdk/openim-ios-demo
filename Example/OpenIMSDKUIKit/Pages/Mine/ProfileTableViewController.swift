
import Photos
import RxSwift
import ProgressHUD
import UIKit
import OUICore
import OUIIM
import Kingfisher

class ProfileTableViewController: OUIIM.ProfileTableViewController {
    
    override var rowItems: [[ProfileTableViewController.RowType]] {
#if ENABLE_ORGANIZATION
        [[.avatar, .nickname, .gender, .birthday],
         [.landline, .phone, .email]
        ]
#else
        [[.avatar, .nickname, .gender, .birthday],
         [.phone, .email]
        ]
#endif
    }
    
    private let _viewModel = MineViewModel()
    private let _disposeBag = DisposeBag()
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickAvatar()
        v.didPhotoSelected = { [weak self] (images: [UIImage], _: [PHAsset]) in
            guard var first = images.first else { return }
            ProgressHUD.animate(interaction: false)
            first = first.compress(expectSize: 20 * 1024)
            let result = FileHelper.shared.saveImage(image: first)
            
            if result.isSuccess {
                self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { [weak self] progress in

                }, onComplete: { [weak self] code, msg in
                    if code == 0 {
                        self?.user?.faceURL = "file://" + result.fullPath
                        self?.reloadData()
                        ProgressHUD.dismiss()
                    } else {
                        ProgressHUD.error(msg)
                    }
                })
            } else {
                ProgressHUD.dismiss()
            }
        }
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, _: URL?) in
            guard let sself = self else { return }
            if var photo {
                ProgressHUD.animate(interaction: false)
                
                photo = photo.compress(expectSize: 20 * 1024)
                let result = FileHelper.shared.saveImage(image: photo)
                if result.isSuccess {
                    self?._viewModel.uploadFile(fullPath: result.fullPath, onProgress: { [weak self] progress in

                    }, onComplete: { [weak self] code, msg in
                        if code == 0 {
                            self?.user?.faceURL = "file://" + result.fullPath
                            self?.reloadData()
                            ProgressHUD.dismiss()
                        } else {
                            ProgressHUD.error(msg)
                        }
                    })
                }
            }
        }
        return v
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getUserOrMemberInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "我的信息".innerLocalized()
        canEdit = (LoginType(rawValue: UserDefaults.standard.integer(forKey: loginTypeKey)) ?? .phone) != .account
        tableView.allowsSelection = canEdit
    }
    
    private func callPhoneTel(phone : String){
        let  phoneUrlStr = "tel://" + phone
        if let url = URL(string: phoneUrlStr), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowType = rowItems[indexPath.section][indexPath.row]
        
#if ENABLE_ORGANIZATION
        switch rowType {
        case .phone:
            callPhoneTel(phone: user?.phoneNumber ?? "")
            break
        case .qrcode:
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user?.userID))
            vc.nameLabel.text = user?.nickname
            vc.avatarView.setAvatar(url: user?.faceURL, text: user?.nickname)
            vc.tipLabel.text = "qrcodeHint".localized()
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.currentUserRelay.value?.userID
            ProgressHUD.success("复制成功".localized())
        case .email:
            if let email = user?.email, !email.isEmpty {
                UIPasteboard.general.string = email
                ProgressHUD.success("复制成功".localized())
            }
            break
        default:
            break
        }
        return
#endif
        
        switch rowType {
        case .avatar:
            presentSelectedPictureActionSheet { [weak self] in
                guard let self else { return }
                _photoHelper.presentPhotoLibrary(byController: self)
            } cameraHandler: {[weak self] in
                guard let self else { return }
                _photoHelper.presentCamera(byController: self)
            }
            
        case .nickname:
            let vc = ModifyNicknameViewController()
            vc.titleLabel.text = "修改昵称".innerLocalized()
            vc.subtitleLabel.text = nil
            vc.avatarView.setAvatar(url: user?.faceURL, text: user?.nickname)
            vc.nameTextField.text = user?.nickname
            vc.completeBtn.rx.tap.subscribe(onNext: { [weak self, weak vc] in
                guard let text = vc?.nameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                      !text.isEmpty else { return }
                ProgressHUD.animate()
                self?._viewModel.updateNickname(text) { [weak self, weak vc] code, msg in
                    if code == 0 {
                        self?.user?.nickname = text
                        self?.reloadData()
                        ProgressHUD.dismiss()
                    } else {
                        ProgressHUD.error(msg)
                    }
                    vc?.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: vc.disposeBag)
            navigationController?.pushViewController(vc, animated: true)
        case .gender:
            presentActionSheet(action1Title: "男".innerLocalized(), action1Handler: { [weak self] in
                ProgressHUD.animate()
                self?._viewModel.updateGender(.male) { [weak self] code, msg in
                    if code == 0 {
                        self?.user?.gender = .male
                        self?.reloadData()
                        ProgressHUD.dismiss()
                    } else {
                        ProgressHUD.error(msg)
                    }
                }
            }, action2Title: "女".innerLocalized()) { [weak self] in
                ProgressHUD.animate()
                self?._viewModel.updateGender(.female) { [weak self] code, msg in
                    if code == 0 {
                        self?.user?.gender = .female
                        self?.reloadData()
                        ProgressHUD.dismiss()
                    } else {
                        ProgressHUD.error(msg)
                    }
                }
            }
        case .birthday:
            JNDatePickerView.show(onWindowOfView: view) { (pickerView: JNDatePickerView) in
                pickerView.datePicker.maximumDate = Date()
                pickerView.datePicker.minimumDate = Date(timeIntervalSince1970: 0)
            } confirmAction: { [weak self] (selectedDate: Date) in
                ProgressHUD.animate()
                let timeStamp = selectedDate.timeIntervalSince1970
                self?._viewModel.updateBirthday(timeStampSeconds: Int(timeStamp)) { [weak self] code, msg in
                    if code == 0 {
                        self?.user?.birth = Int(timeStamp) * 1000
                        self?.reloadData()
                        ProgressHUD.dismiss()
                    } else {
                        ProgressHUD.error(msg)
                    }
                }
            }
        case .phone, .landline:
            callPhoneTel(phone: user?.phoneNumber ?? "")
            break
        case .qrcode:
            guard let user = _viewModel.currentUserRelay.value else { return }
            let vc = QRCodeViewController(idString: IMController.addFriendPrefix.append(string: user.userID))
            vc.nameLabel.text = user.nickname
            vc.avatarView.setAvatar(url: user.faceURL, text: user.nickname)
            vc.tipLabel.text = "qrcodeHint".localized()
            navigationController?.pushViewController(vc, animated: true)
        case .identifier:
            UIPasteboard.general.string = _viewModel.currentUserRelay.value?.userID
            ProgressHUD.success("复制成功".localized())
        case .email:
            updateEmail()
            break
        case .spacer:
            break
        }
    }
    
    private func updateEmail() {
        let vc = SimpleInputViewController()
        vc.maxLength = 100
        vc.textField.text = user?.email
        vc.onComplete = { [weak self] inputText in
            if inputText.isValidEmail() {
                ProgressHUD.animate()
                self?._viewModel.updateUserInfo(email: inputText) { [weak self] code, msg in
                    if code == 0 {
                        self?.user?.email = inputText
                        self?.reloadData()
                        
                        ProgressHUD.dismiss()
                        self?.navigationController?.popViewController(animated: true)
                    } else {
                        ProgressHUD.error(msg)
                    }
                }
            } else {
                ProgressHUD.error("emailFormatError".localized())
            }
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    deinit {
#if DEBUG
        print("dealloc \(type(of: self))")
#endif
    }
}
