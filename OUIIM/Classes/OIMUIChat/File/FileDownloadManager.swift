
import Alamofire

struct DownloadCallBack {
    typealias DownloadProgressReturnVoid = (String, Int, Int) -> Void
    typealias CompletionReturnVoid = (String, URL) -> Void
}

public struct FileDownloadRequest {
    let request: DownloadRequest
}

public class FileDownloadManager {
    static let manager = FileDownloadManager()
    
    public func pauseAllDownloadRequest() {
        downloadRequests.values.forEach({ if $0.task?.state == .running { $0.suspend() } })
    }
    
    public func downloadRequest(messageID: String) -> FileDownloadRequest? {
        downloadRequests[messageID] != nil ? FileDownloadRequest(request: downloadRequests[messageID]!) : nil
    }
    
    func setExistsTaskHandler(messageID: String,
                              progress: @escaping DownloadCallBack.DownloadProgressReturnVoid,
                              completion: @escaping DownloadCallBack.CompletionReturnVoid) {
        if let taskIdentifier = messageIDForTaskIdentifier[messageID] {
            
            var taskHandler = tasksHandlers[taskIdentifier]
            taskHandler?[progressKey] = progress
            taskHandler?[completionKey] = completion
            
            tasksHandlers[taskIdentifier] = taskHandler
        }
    }
    
    private let progressKey = "progressKey"
    private let completionKey = "completionKey"
    private let messageIDKey = "messageIDKey"
    private let desURLKey = "desURLKey"
    private let downloader = FileDownloader()
    private var messageIDForTaskIdentifier: [String: Int] = [:]
    private var tasksHandlers: [Int: [String: Any]] = [:]
    
    private var downloadRequests = [String: DownloadRequest]()
        
    func downloadMessageFile(messageID: String,
                             url: URL,
                             name: String? = nil,
                             progress: DownloadCallBack.DownloadProgressReturnVoid? = nil,
                             completion: DownloadCallBack.CompletionReturnVoid? = nil) -> FileDownloadRequest? {
        
        guard let url = try? url.asURL() else { return nil }
        
        downloader.manager.delegate.taskDidComplete = { [weak self] (session, task, error) in
            if let error {
                if let resumeData = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    self?.downloader.resumeData = resumeData
                }
            } else {
                print("taskDidComplete: \(task)")
            }
        }
        
        downloader.manager.delegate.downloadTaskDidFinishDownloadingToURL = { [weak self] (session, downloadTask, location) in
            guard let self,
                  let completion = Self.manager.tasksHandlers[downloadTask.taskIdentifier]?[self.completionKey] as? DownloadCallBack.CompletionReturnVoid,
                  let messageID = Self.manager.tasksHandlers[downloadTask.taskIdentifier]?[self.messageIDKey] as? String,
                    let desURL = Self.manager.tasksHandlers[downloadTask.taskIdentifier]?[self.desURLKey] as? URL else { return }
            do {
                downloadRequests.removeValue(forKey: messageID)
                messageIDForTaskIdentifier.removeValue(forKey: messageID)
                
                let des = URL.init(fileURLWithPath: downloader.filePath)
                try? FileManager.default.moveItem(at: location, to: des)
                completion(messageID, des)
                try? FileManager.default.removeItem(at: desURL)
            } catch let error {
                print("downloadTaskDidFinishDownloadingToURL - error: \(error.localizedDescription)")
            }
        }
        
        downloader.manager.delegate.downloadTaskDidWriteData = { [weak self] (session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
            guard let self,
                  let progress = Self.manager.tasksHandlers[downloadTask.taskIdentifier]?[progressKey] as? DownloadCallBack.DownloadProgressReturnVoid,
                  let messageID = Self.manager.tasksHandlers[downloadTask.taskIdentifier]?[messageIDKey] as? String else { return }
            
            progress(messageID, Int(totalBytesWritten), Int(totalBytesExpectedToWrite))
        }
        
        if let taskIdentifier = messageIDForTaskIdentifier[messageID] {
            var taskHandler = tasksHandlers[taskIdentifier]
            taskHandler?[progressKey] = progress
            taskHandler?[completionKey] = completion
            
            tasksHandlers[taskIdentifier] = taskHandler
        }
        
        if let req = downloadRequests[messageID] {
            return FileDownloadRequest(request: req)
        }
        
        let request = downloader.download(url, name: name)
        guard let taskIdentifier = request.request.task?.taskIdentifier else { return nil }
        
        tasksHandlers[taskIdentifier] = [progressKey: progress,
                                       completionKey: completion,
                                        messageIDKey: messageID,
                                           desURLKey: request.desURL]
        messageIDForTaskIdentifier[messageID] = taskIdentifier
        downloadRequests[messageID] = request.request
        
        return FileDownloadRequest(request: request.request)
    }
}


class FileDownloader: NSObject {
    var resumeData: Data?
    var request: DownloadRequest?
    public private(set) var filePath: String!
    
    lazy var manager: SessionManager = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.oim.file.download.manager.session.manager")
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.sharedContainerIdentifier = "com.oim.file.download.manager.session.manager"
        let manager = SessionManager(configuration: configuration)
        manager.startRequestsImmediately = true
        
        return manager
    }()
    
    func download(_ url: URLConvertible, name: String? = nil) -> (request: DownloadRequest, desURL: URL) {
        let ext = try! url.asURL().absoluteString.split(separator: ".").last!
        var r = name
        
        if r == nil {
            r = try! url.asURL().md5 + ".\(ext)"
        }

        filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/\(r!)"
        print("download file to des path:\(filePath)")
        
        let destination: DownloadRequest.DownloadFileDestination = { [weak self] _, _ in
            return (URL(fileURLWithPath: self!.filePath), [.removePreviousFile, .createIntermediateDirectories])
        }
        
        if self.resumeData != nil {
            request = manager.download(resumingWith: self.resumeData!)
        } else {
            if let resumeData = request?.resumeData {
                request = manager.download(resumingWith: resumeData)
            } else {
                request = manager.download(url, to: destination)
            }
        }
        return (request: request!, desURL: (URL(fileURLWithPath: filePath)))
    }
}
