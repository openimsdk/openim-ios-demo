
import InputBarAccessoryView
import UIKit
import OUICore
import Photos
import MobileCoreServices
import ProgressHUD

enum CustomAttachment {
    case image(String, String)
}

protocol CoustomInputBarAccessoryViewDelegate: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith attachments: [CustomAttachment])
    func inputBar(_ inputBar: InputBarAccessoryView, didPressPadItemWith type: PadItemType)
    func uploadFile(image: UIImage, completion: @escaping (URL) -> Void)
    func didPressRemoveReplyButton()
    func inputTextViewDidChange()
}

extension CoustomInputBarAccessoryViewDelegate {
    func inputBar(_: InputBarAccessoryView, didPressSendButtonWith _: [CustomAttachment]) { }
    func inputBar(_: InputBarAccessoryView, didPressPadItemWith _: PadItemType) {}
    func didPressRemoveReplyButton() {}
    func inputTextViewDidChange() {}
}

let buttonSize = 35.0

class CoustomInputBarAccessoryView: InputBarAccessoryView {
    
    public var identity: String!
    
    private lazy var _photoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickImageForChat() { [weak self] asset in
            guard let self else { return false }
            
            var canSelect = false
            let resources = PHAssetResource.assetResources(for: asset)
            
            for resource in resources {
                let uti = resource.uniformTypeIdentifier
                
                if allowSendImageTypeHelper(uti: uti) {
                    canSelect = true
                    
                    break
                }
            }
            
            if !canSelect {
                let alertController = AlertViewController(message: "supportsTypeHint".innerLocalized(), preferredStyle: .alert)
                let cancelAction = AlertAction(title: "determine".innerLocalized(), style: .cancel)
                alertController.addAction(cancelAction)


                currentViewController().present(alertController, animated: true)
            }
            
            return canSelect
        }
        v.didPhotoSelected = { [weak self, weak v] (images: [UIImage], assets: [PHAsset]) in
            guard let self else { return }
            sendButton.startAnimating()
            
            for (index, asset) in assets.enumerated() {
                switch asset.mediaType {
                case .video:
                    break
                case .image:
                    PhotoHelper.isGIF(asset: asset) { data, isGif in
                        if isGif {
                            if let data {
                                let r = FileHelper.saveImageData(data: data)
                                
                                self.sendAttachments(attachments: [.image(r.relativeFilePath,
                                                                          r.fullPath)])
                            }
                        } else {
                            var item = images[index].compress(expectSize: 300 * 1024)
                            let r = FileHelper.shared.saveImage(image: item)

                            self.sendAttachments(attachments: [.image(r.relativeFilePath,
                                                                      r.fullPath)])
                        }
                    }
                default:
                    break
                }
            }
        }
        
        return v
    }()
    
    private lazy var _selectedPhotoHelper: PhotoHelper = {
        let v = PhotoHelper()
        v.setConfigToPickImageForAddFaceEmoji()
        
        return v
    }()
    
    private func allowSendImageTypeHelper(uti: String) -> Bool {
        return uti == kUTTypePNG as String ||
        uti == kUTTypeJPEG as String ||
        uti == kUTTypeGIF as String ||
        uti == kUTTypeBMP as String ||
        uti == "public.webp" ||
        uti == kUTTypeMPEG4 as String ||
        uti == kUTTypeQuickTimeMovie as String ||
        uti == "public.heic"
    }
    
    lazy var moreButton: InputBarButtonItem = {
        let v = InputBarButtonItem()
            .configure {
                $0.image = UIImage(nameInBundle: "inputbar_more_normal_icon")
                $0.setImage(UIImage(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
                $0.setImage(UIImage(nameInBundle: "inputbar_more_disable_icon"), for: .disabled)
                $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
            }.onTouchUpInside { [weak self] item in
                guard let self else { return }
                item.isSelected = !item.isSelected
                print("moreButton Tapped:\(item.isSelected)")
                inputTextView.inputView = item.isSelected ? inputPadView : nil
                inputTextView.reloadInputViews()
                inputTextView.becomeFirstResponder()
                setTextViewCursorColor()
            }
        
        return v
    }()
    
    private lazy var inputPadView: InputPadView = {
        let v = InputPadView()
        v.delegate = self
        
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupSubViews() {
        layer.masksToBounds = true
        backgroundColor = .secondarySystemBackground
        backgroundView.backgroundColor = .secondarySystemBackground
        inputTextView.backgroundColor = .systemBackground
        inputTextView.textColor = .c0C1C33
        inputTextView.font = .f17
        inputTextView.placeholder = nil
        inputTextView.layer.cornerRadius = 5
        
        leftStackView.alignment = .center
        rightStackView.alignment = .center
        rightStackView.spacing = 8.0
        
        padding = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 12)
        middleContentViewPadding = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 8)
        
        configLeftButtons()
        configRightButton()
    }
    
    private func configLeftButtons() {
        setLeftStackViewWidthConstant(to: buttonSize + 16, animated: false)
        setStackViewItems([], forStack: .left, animated: false)
    }
    
    private func configRightButton() {
        sendButton.configure {
            $0.title = nil
            $0.image = UIImage(nameInBundle: "inputbar_pad_send_normal_icon")
            $0.setImage(UIImage(nameInBundle: "inputbar_pad_send_disable_icon"), for: .disabled)
            $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
        }
        setRightStackViewWidthConstant(to: buttonSize * 2 + 8, animated: false)
        setStackViewItems([moreButton], forStack: .right, animated: false)
    }

    private func toggleMoreButtonStatus(_ showMore: Bool) {
        if showMore {
            setStackViewItems([moreButton], forStack: .right, animated: false)
        } else {
            setStackViewItems([sendButton], forStack: .right, animated: false)
        }
    }

    private func sendAttachments(attachments: [CustomAttachment]) {
        DispatchQueue.main.async { [self] in
            if attachments.count > 0 {
                (self.delegate as? CoustomInputBarAccessoryViewDelegate)?
                    .inputBar(self, didPressSendButtonWith: attachments)
            }
        }
    }
    
    private func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        let cur = currentViewController()
  
        if case .camera = sourceType {
            _photoHelper.presentCamera(byController: cur)
        } else {
            _photoHelper.presentPhotoLibrary(byController: cur)
        }
    }

    private func currentViewController() -> UIViewController {
        var rootViewController: UIViewController?
        for window in UIApplication.shared.windows {
            if window.rootViewController != nil {
                rootViewController = window.rootViewController
                break
            }
        }
        var viewController = rootViewController
        if viewController?.presentedViewController != nil {
            viewController = viewController!.presentedViewController
        }
        return viewController!
    }
    
    public func enableInput(enable: Bool = true) {
        inputTextView.isEditable = enable
        inputTextView.textAlignment = enable ? .left : .center
        inputTextView.placeholderLabel.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        
        moreButton.isEnabled = enable
        sendButton.isEnabled = enable
        
        if !enable {
            inputTextView.resignFirstResponder()
        }
    }
    
    public func inputResignFirstResponder() {
        moreButton.isSelected = false
        
        inputTextView.resignFirstResponder()
        inputTextView.inputView = nil
        inputTextView.reloadInputViews()
    }
    
    public func inputBecomeFirstResponder() {
        moreButton.isSelected = false
        
        inputTextView.inputView = nil
        inputTextView.reloadInputViews()
    }
    
    private func setTextViewCursorColor(clear: Bool = true) {
        inputTextView.tintColor = clear ? .clear : .systemBlue
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        if hitView == inputTextView, inputTextView.inputView != nil {
            inputBecomeFirstResponder()
            setTextViewCursorColor(clear: false)
        }
        
        return hitView
    }
    
    override func inputTextViewDidBeginEditing() {
        setTextViewCursorColor(clear: false)
    }
    
    override func inputTextViewDidChange() {
        super.inputTextViewDidChange()
        toggleMoreButtonStatus(inputTextView.text.isEmpty)
        
        if inputTextView.text == UIPasteboard.general.string {
            let range = NSMakeRange(inputTextView.text.count - 1, 1)
            inputTextView.scrollRangeToVisible(range)
        }
        
        (delegate as? CoustomInputBarAccessoryViewDelegate)?.inputTextViewDidChange()
    }
    
    class Spacer: UIView, InputItem {
        var inputBarAccessoryView: InputBarAccessoryView?
        var parentStackViewPosition: InputStackView.Position?
        
        func textViewDidChangeAction(with textView: InputTextView) {}
        func keyboardSwipeGestureAction(with gesture: UISwipeGestureRecognizer) {}
        func keyboardEditingEndsAction() {}
        func keyboardEditingBeginsAction() {}
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            translatesAutoresizingMaskIntoConstraints = false
        }
        
        var width: CGFloat = 35.0 {
            didSet {
                NSLayoutConstraint.activate([
                    widthAnchor.constraint(equalToConstant: width)
                ])
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

extension CoustomInputBarAccessoryView: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerWillDismiss(_: UIPresentationController) {
        isHidden = false
    }
}

extension CoustomInputBarAccessoryView: InputPadViewDelegate {
    func didSelect(type: PadItemType) {
        (self.delegate as? CoustomInputBarAccessoryViewDelegate)?
            .inputBar(self, didPressPadItemWith: type)
        switch type {
        case .album:
            showImagePickerController(sourceType: .photoLibrary)
        default:
            break
        }
    }
}
