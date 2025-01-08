
import Foundation
import OUICore

enum FileDownloadStatus {
    case normal
    case downloading
    case paused
    case completion
}

final class FileController: CellBaseController {
    
    var image = UIImage(nameInBundle: "chat_msg_file_zip_disable_icon") 
    var highlightedImage = UIImage(nameInBundle: "chat_msg_file_zip_normal_icon")
    
    var name: String?
    var displayName: String?
    var length: String?
    
    private var documentInteractionController: UIDocumentInteractionController!
    private var baseViewController: UIViewController!
    private var source: FileMessageSource!
    private var isLocallyStored: Bool = false
    private var downloadRequest: FileDownloadRequest?
        
    weak var view: FileView? {
        didSet {
            if isLocallyStored {
                status = .completion
            }
            view?.reloadData()
        }
    }
    
    var progress: CGFloat = 0 {
        didSet {
            view?.reloadData()
        }
    }
    
    var status: FileDownloadStatus = .normal
    
    func pause() {
        status = .paused
        downloadRequest?.request.suspend()
    }
    
    func resume() {
        status = .downloading
            
        if downloadRequest == nil {
            loadFile()
        } else {
            downloadRequest?.request.resume()
        }
    }
    
    func cancel() {
        downloadRequest?.request.cancel()
    }
    
    func prepareForReuse(reStart: Bool = true) {
        if let req = FileDownloadManager.manager.downloadRequest(messageID: messageID) {
            downloadRequest = req
            FileDownloadManager.manager.setExistsTaskHandler(messageID: messageID) { [self] (messageID, written, total) in
                
                guard self.messageID == messageID else { return }
                
                DispatchQueue.main.async { [self] in
                    self.progress = CGFloat(written) / CGFloat(total)
                }
            } completion: { [weak self] (messageID, url) in
                FileHelper.shared.saveFile(from: url.path, name: self?.name)
                
                DispatchQueue.main.async { [self] in
                    guard let self else { return }
                    self.status = .completion
                    self.view?.reloadData()
                    self.delegate?.reloadMessage(with: self.messageID)
                }
            }
            if reStart {
                resume()
            }
        }
    }

    init(source: FileMessageSource, isLocallyStored: Bool, messageID: String, bubbleController: BubbleController) {
        super.init(messageID: messageID, bubbleController: bubbleController)
        
        self.displayName = source.name
        
        let n = source.name?.split(separator: ".")
        let ext = n?.last
        let name = n?.first
        
        if let ext, let name {
            self.name = "\(name)_\(messageID).\(ext)"
        }
        
        self.source = source
        self.length = FileHelper.formatLength(length: source.length)
        self.obtainIconImage(url: source.url)
        self.isLocallyStored = isLocallyStored
        
        prepareForReuse()
    }
    
    private func loadFile() {
        
        if isLocallyStored {
            status = .completion
            view?.reloadData()
        } else {
            downloadRequest = FileDownloadManager.manager.downloadMessageFile(messageID: messageID,
                                                                              url: source.url,
                                                                              name: name) { [self] (messageID, written, total) in
                
                guard self.messageID == messageID else { return }
                
                DispatchQueue.main.async { [self] in
                    self.progress = CGFloat(written) / CGFloat(total)
                }
            } completion: { [weak self] (messageID, url) in
                FileHelper.shared.saveFile(from: url.path, name: self?.name)
                
                DispatchQueue.main.async { [self] in
                    guard let self else { return }
                    self.status = .completion
                    self.view?.reloadData()
                    self.delegate?.reloadMessage(with: self.messageID)
                }
            }
        }
    }
    
    private func obtainIconImage(url: URL) {
        let ext = url.relativeString.split(separator: ".").last
        switch ext {
        case "xls", "xlsx":
            image = UIImage(nameInBundle: "chat_msg_file_excel_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_excel_normal_icon")
        case "ppt", "pptx":
            image = UIImage(nameInBundle: "chat_msg_file_ppt_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_ppt_normal_icon")
        case "doc", "docx":
            image = UIImage(nameInBundle: "chat_msg_file_word_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_word_normal_icon")
        case "pdf":
            image = UIImage(nameInBundle: "chat_msg_file_pdf_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_pdf_normal_icon")
        case "zip", "rar", "7z":
            image = UIImage(nameInBundle: "chat_msg_file_zip_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_zip_normal_icon")
        default:
            image = UIImage(nameInBundle: "chat_msg_file_unknown_disable_icon")
            highlightedImage = UIImage(nameInBundle: "chat_msg_file_unknown_normal_icon")
        }
    }
    
    func action() {
        
        if let path = FileHelper.shared.exsit(path: source.url.relativeString, name: name) {
            let url = URL(fileURLWithPath: path)
            let temp = FileMessageSource(url: url, length: source.length, name: source.name, relativePath: source.relativePath)
            
            onTap?(.file(temp, isLocallyStored: true))
        } else {
            if status == .downloading {
                pause()
            } else {
                resume()
            }
            view?.reloadData()
        }
    }
}
