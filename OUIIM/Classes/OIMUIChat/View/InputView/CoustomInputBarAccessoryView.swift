
import InputBarAccessoryView
import UIKit
import OUICore
import Photos
import MobileCoreServices
import ISEmojiView
import ProgressHUD

enum CustomAttachment {
    case image(String, String)
    case audio(String, Int)
    case video(String, String, String, Int)
    case file(String)
    case face(URL, String?)
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
    
    private let documentPicker = UIDocumentBrowserViewController(forOpeningFilesWithContentTypes: ["public.item"])

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
                    ProgressHUD.animate("compressing".innerLocalized())
                    PhotoHelper.compressVideoToMp4(asset: asset, thumbnail: images[index]) { main, thumb, duration in
                        ProgressHUD.dismiss()
                        self.sendAttachments(attachments: [.video(thumb.relativeFilePath,
                                                                  thumb.fullPath,
                                                                  main.fullPath,
                                                                  duration)])
                    }
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
        
        v.didCameraFinished = { [weak self] (photo: UIImage?, videoPath: URL?) in
            guard let self else { return }
            sendButton.startAnimating()
            
            if let photo {
                var item = photo.compress(expectSize: 300 * 1024)
                let r = FileHelper.shared.saveImage(image: item)
                
                self.sendAttachments(attachments: [.image(r.relativeFilePath,
                                                          r.fullPath)])
                v.saveImageToAlbum(image: photo, showToast: false)
            }
            
            if let videoPath {
                ProgressHUD.animate("compressing".innerLocalized())
                PhotoHelper.getVideoAt(url: videoPath) { main, thumb, duration in
                    v.saveVideoToAlbum(path: URL(fileURLWithPath: main.fullPath).absoluteString, showToast: false, removeOrigin: false)
                    ProgressHUD.dismiss()
                    
                    self.sendAttachments(attachments: [.video(thumb.relativeFilePath,
                                                              thumb.fullPath,
                                                              main.fullPath,
                                                              duration)])
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
    
    let audioMaxDuration = 60 
    var audioDuration = 0 
    var audioRecordTimer: Timer?
    
    lazy var audioButton: InputBarButtonItem = {
        let v = InputBarButtonItem()
            .configure {
                $0.image = UIImage(nameInBundle: "inputbar_audio_btn_normal_icon")
                $0.setImage(UIImage(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
                $0.setImage(UIImage(nameInBundle: "inputbar_audio_btn_disable_icon"), for: .disabled)
                $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
            }.onTouchUpInside { [weak self] item in
                guard let self else { return }
                requestMicrophoneAccess { [self] granted in
                    guard granted else { return }
                    
                    item.isSelected = !item.isSelected
                    print("audioButton Tapped:\(item.isSelected)")
                    self.emojiButton.isSelected = false
                    self.moreButton.isSelected = false
                    
                    self.showAudioInputButtonView(item.isSelected, becomeFirstResponder: true)
                }
            }
        return v
    }()
    
    private func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        
        switch audioSession.recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("Microphone access granted.")
                    } else {
                        print("Microphone access denied.")
                    }
                    completion(granted)
                }
            }
        case .denied:
            print("Microphone access previously denied. Direct user to settings.")
            completion(false)
        case .granted:
            print("Microphone access already granted.")
            completion(true)
        @unknown default:
            print("Unknown microphone permission status.")
            completion(false)
        }
    }

    
    lazy var audioInputButton: InputBarButtonItem = {
        let v = InputBarButtonItem()
            .configure {
                $0.backgroundColor = .systemBackground
                $0.title = "按住说话".innerLocalized()
                $0.setTitle("松手发送".innerLocalized(), for: .disabled)
                $0.setTitleColor(.c0C1C33, for: .normal)
                $0.titleLabel?.font = .systemFont(ofSize: 16)
            }
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(audioButtonLongPress))
        v.addGestureRecognizer(longPress)
        
        return v
    }()
    
    @objc
    private func audioButtonLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        
        let point = gestureRecognizer.location(in: gestureRecognizer.view)
        
        if point.y < 0, !inputAudioView.isIdel {

            inputAudioView.toggleStatus()
        } else if point.y > 0, inputAudioView.isIdel {
            inputAudioView.toggleStatus()
        }
        
        if case UIGestureRecognizer.State.began = gestureRecognizer.state {

            showAudioInputView()
            startRecordAudio()
            
        } else if case UIGestureRecognizer.State.ended = gestureRecognizer.state {

            showAudioInputView(show: false)
            stopRecordAudio()
            
            if point.y < 0 {
                deleteRecordAudio()
            } else {
                print("发送")
            }
        }
    }
    
    private lazy var audioRecorder: AVAudioRecorder = {
        let voicePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(UUID().uuidString).m4a"
        let fileUrl = URL(fileURLWithPath: voicePath)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0
        ]
        do {
            let v = try AVAudioRecorder(url: fileUrl, settings: settings)
            v.delegate = self
            
            return v
        } catch {
            print("error：\(error.localizedDescription)")
        }
        return AVAudioRecorder()
    }()
    
    lazy var inputAudioView: InputAudioView = {
        let v = InputAudioView()
        
        return v
    }()
    
    lazy var emojiButton: InputBarButtonItem = {
        let v = InputBarButtonItem()
            .configure {
                $0.image = UIImage(nameInBundle: "inputbar_emoji_btn_normal_icon")
                $0.setImage(UIImage(nameInBundle: "inputbar_keyboard_btn_icon"), for: .selected)
                $0.setImage(UIImage(nameInBundle: "inputbar_emoji_btn_disable_icon"), for: .disabled)
                $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
            }.onTouchUpInside { [weak self] item in
                guard let self else { return }
                item.isSelected = !item.isSelected
                print("emojiButton Tapped:\(item.isSelected)")
                showAudioInputButtonView(false)
                audioButton.isSelected = false
                moreButton.isSelected = false
                inputTextView.inputView = item.isSelected ? emojiView : nil
                inputTextView.reloadInputViews()
                inputTextView.becomeFirstResponder()
                setTextViewCursorColor()
            }
        
        return v
    }()
    
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
                showAudioInputButtonView(false)
                emojiButton.isSelected = false
                inputTextView.inputView = item.isSelected ? inputPadView : nil
                inputTextView.reloadInputViews()
                inputTextView.becomeFirstResponder()
                setTextViewCursorColor()
            }
        
        return v
    }()
    
    lazy var emojiView: EmojiView = {
        let keyboardSettings = KeyboardSettings(bottomType: .topCategories, identity: identity)
        keyboardSettings.countOfRecentsEmojis = 10
        keyboardSettings.updateRecentEmojiImmediately = true
        keyboardSettings.needToShowDeleteButton = true
        let v = EmojiView(keyboardSettings: keyboardSettings)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.delegate = self
        
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
    
    lazy var attachmentManager: AttachmentManager = { [unowned self] in
        let manager = AttachmentManager()
        manager.delegate = self
        
        return manager
    }()
    
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
        setupGestureRecognizers()
        
        inputPlugins.append(attachmentManager)
    }
    
    private func configLeftButtons() {
        setLeftStackViewWidthConstant(to: buttonSize + 16, animated: false)
        setStackViewItems([audioButton], forStack: .left, animated: false)
    }
    
    private func configRightButton() {
        sendButton.configure {
            $0.title = nil
            $0.image = UIImage(nameInBundle: "inputbar_pad_send_normal_icon")
            $0.setImage(UIImage(nameInBundle: "inputbar_pad_send_disable_icon"), for: .disabled)
            $0.setSize(CGSize(width: buttonSize, height: buttonSize), animated: false)
        }
        setRightStackViewWidthConstant(to: buttonSize * 2 + 8, animated: false)
        setStackViewItems([emojiButton, moreButton], forStack: .right, animated: false)
    }
    
    private func setupGestureRecognizers() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.down]
        for direction in directions {
            let gesture = UISwipeGestureRecognizer(target: self,
                                                   action: #selector(onSwipeDown(_:)))
            gesture.direction = direction
            self.addGestureRecognizer(gesture)
        }
    }
    
    @objc
    private func onSwipeDown(_ gesture: UIGestureRecognizer) {

        if moreButton.isSelected {
            moreButton.isSelected = false
            
            UIView.animate(withDuration: 0.3) { [self] in
                layoutIfNeeded()
            }
        }
    }

    private func toggleMoreButtonStatus(_ showMore: Bool) {
        if showMore {
            setStackViewItems([emojiButton, moreButton], forStack: .right, animated: false)
        } else {
            setStackViewItems([emojiButton, sendButton], forStack: .right, animated: false)
        }
    }

    private func showAudioInputButtonView(_ enableInput: Bool = true, becomeFirstResponder: Bool = false) {
        if enableInput {
            inputTextView.inputView = nil
            inputTextView.resignFirstResponder()
            inputTextView.reloadInputViews()
            setMiddleContentView(audioInputButton, animated: false)
        } else {
            setMiddleContentView(inputTextView, animated: false)
            if becomeFirstResponder {
                inputTextView.becomeFirstResponder()
            }
            audioButton.isSelected = false
        }
    }

    private func showAudioInputView(show: Bool = true) {
        
        inputAudioView.durationLabel.text = nil
        
        if (!show) {
            audioInputButton.isEnabled = true
            inputAudioView.removeFromSuperview()
            return
        }
        
        guard let superView = currentViewController().view else { return }
        audioInputButton.isEnabled = false
        
        superView.addSubview(inputAudioView)
        inputAudioView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            inputAudioView.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            inputAudioView.topAnchor.constraint(equalTo: superView.topAnchor),
            inputAudioView.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            inputAudioView.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
        ])
    }

    private func showDocumentPicker() {
        documentPicker.delegate = self
        currentViewController().present(documentPicker, animated: true)
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

    private func startRecordAudio() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self else { return }
            if !granted {

                return
            }
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(AVAudioSession.Category.record)
                try session.setActive(true)
            } catch {
                print("AudioSession init error：", error.localizedDescription)
            }
            if !self.audioRecorder.prepareToRecord() {
                print("prepare record failed")
                return
            }
            if !self.audioRecorder.record() {
                print("start record failed")
                return
            }
            self.audioDuration = 0
            DispatchQueue.main.async { [self] in
                self.inputAudioView.durationLabel.text = "00:00"
            }
            self.audioRecordTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
                guard let self else { return }
                self.audioDuration += 1
                
                if self.audioMaxDuration - self.audioDuration <= 0 {
                    self.showAudioInputView(show: false)
                    self.stopRecordAudio()
                }
                
                self.inputAudioView.durationLabel.text = String(format: "%02d:%02d", self.audioDuration / 60, self.audioDuration % 60)
            })
        }
    }

    private func deleteRecordAudio() {
        if !audioRecorder.deleteRecording() {
            print("\(#function) failure")
        }
    }

    private func stopRecordAudio() {
        if audioRecorder.isRecording {
            audioRecorder.stop()
            audioRecordTimer?.invalidate()
            audioRecordTimer = nil
            try? AVAudioSession.sharedInstance().setActive(false)
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
        
        audioButton.isEnabled = enable
        emojiButton.isEnabled = enable
        moreButton.isEnabled = enable
        sendButton.isEnabled = enable
        
        if !enable {
            inputTextView.resignFirstResponder()
        }
    }
    
    public func inputResignFirstResponder() {
        audioButton.isSelected = false
        emojiButton.isSelected = false
        moreButton.isSelected = false
        
        inputTextView.resignFirstResponder()
        inputTextView.inputView = nil
        inputTextView.reloadInputViews()
    }
    
    public func inputBecomeFirstResponder() {
        audioButton.isSelected = false
        emojiButton.isSelected = false
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


extension CoustomInputBarAccessoryView: AttachmentManagerDelegate {
    func attachmentManager(_ manager: AttachmentManager, shouldBecomeVisible: Bool) {
        
    }
}


extension CoustomInputBarAccessoryView: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerWillDismiss(_: UIPresentationController) {
        isHidden = false
    }
}

extension CoustomInputBarAccessoryView: UIDocumentBrowserViewControllerDelegate {
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let url = documentURLs.first, url.startAccessingSecurityScopedResource() else { return }
        
        let coordinator = NSFileCoordinator()
        var err: NSErrorPointer = nil
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: err) { newURL in
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: newURL.path)
                if let fileSize = attributes[.size] as? Int64, fileSize == 0 {
                    controller.presentAlert(title: "不能发送空文件".innerLocalized(), confirmHandler: nil)
                    return
                }
            } catch {
                print("Error checking file size: \(error.localizedDescription)")
            }
            
            var desPath = FileHelper.shared.exsit(path: newURL.path, name: newURL.lastPathComponent)
            
            if desPath == nil {
                desPath = FileHelper.shared.saveFile(from: newURL.path, name: newURL.lastPathComponent).fullPath
            }
            
            self.sendAttachments(attachments: [.file(desPath!)])
            controller.dismiss(animated: true)
        }
    }
}

extension CoustomInputBarAccessoryView: InputPadViewDelegate {
    func didSelect(type: PadItemType) {
        (self.delegate as? CoustomInputBarAccessoryViewDelegate)?
            .inputBar(self, didPressPadItemWith: type)
        switch type {
        case .album:
            showImagePickerController(sourceType: .photoLibrary)
        case .camera:
            showImagePickerController(sourceType: .camera)
        case .file:
            showDocumentPicker()
        default:
            break
        }
    }
}

extension CoustomInputBarAccessoryView: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag, audioDuration > 0, !inputAudioView.isIdel else { return }
        
        let path = recorder.url.path
        let ext = path.split(separator: ".").last!
        let p = FileHelper.shared.saveAudio(from: path, name: "\(UUID().uuidString).\(ext)").fullPath
        
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
        } catch (let e) {
            print("\(#function) catch error: \(e)")
        }
        
        sendAttachments(attachments: [.audio(p, audioDuration)])
    }
}

extension CoustomInputBarAccessoryView: EmojiViewDelegate {
    
    func emojiViewDidSelectEmoji(_ emoji: String, emojiView: EmojiView) {
        inputTextView.insertText(emoji)
    }
    
    func emojiViewDidPressChangeKeyboardButton(_ emojiView: EmojiView) {
        inputTextView.inputView = nil
        inputTextView.keyboardType = .default
        inputTextView.reloadInputViews()
    }
    
    func emojiViewDidPressDeleteBackwardButton(_ emojiView: EmojiView) {
        inputTextView.deleteBackward()
    }
    
    func emojiViewDidPressDismissKeyboardButton(_ emojiView: EmojiView) {
        inputTextView.resignFirstResponder()
    }
    
    func emojiViewDidAddFace(_ addEmoji: ((URL) -> Void)?, emojiView: ISEmojiView.EmojiView) {
        
        _selectedPhotoHelper.didPhotoSelected = { [weak self] (images: [UIImage], assets: [PHAsset]) in
            guard let self else { return }
            
            for (index, asset) in assets.enumerated() {
                switch asset.mediaType {
                case .image:
                    (self.delegate as? CoustomInputBarAccessoryViewDelegate)?.uploadFile(image: images[index]) { url in
                        addEmoji?(url)
                    }
                default:
                    break
                }
            }
        }
        
        _selectedPhotoHelper.didCameraFinished = { [weak self] (photo: UIImage?, videoPath: URL?) in
            guard let self else { return }
    
            if let photo {
                let r = FileHelper.shared.saveImage(image: photo)
                (self.delegate as? CoustomInputBarAccessoryViewDelegate)?.uploadFile(image: photo) { url in
                    addEmoji?(url)
                }
            }
        }
        
        _selectedPhotoHelper.presentPhotoLibrary(byController: currentViewController())
    }
    
    func emojiViewDidSelectFace(_ emoji: FaceEmoji, emojiView: EmojiView) {
        (self.delegate as? CoustomInputBarAccessoryViewDelegate)?.inputBar(self, didPressSendButtonWith: [.face(emoji.imageURL, emoji.localImagePath)])
    }
}
