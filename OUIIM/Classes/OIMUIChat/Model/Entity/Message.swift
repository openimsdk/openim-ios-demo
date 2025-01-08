
import ChatLayout
import DifferenceKit
import Foundation
import OUICore
import CoreLocation

enum MessageType: Hashable {
    case incoming
    case outgoing
    
    var isIncoming: Bool {
        self == .incoming
    }
}

enum MessageStatus: Hashable {
    case sentFailure
    case sending
    case sent(AttachInfo) // After sending successfully, there will be sending status, read status, etc.
    case received
}

enum MessageRawType: Hashable {
    case normal
    case system
    case date
}

enum MessageSessionRawType: Hashable {
    case single
    case group
    case oaNotice
}

enum MediaMessageType: Hashable {
    case image
    case audio
    case video
}

enum TextMessageType: Hashable {
    case text
    case notice
}

enum NoticeType: Hashable {
    case oa
    case other
}

extension ChatItemAlignment {
    
    var isIncoming: Bool {
        self == .leading
    }
}

struct DateGroup: Hashable {
    
    var id: String
    var date: Date
    var value: String {
        Date.timeString(date: date)
    }
    
    init(id: String, date: Date) {
        self.id = id
        self.date = date
    }
}

extension DateGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: DateGroup) -> Bool {
        self == source
    }
}

struct SystemGroup: Hashable {
    
    enum Data: Hashable {
        case text(String)
    }
    
    var id: String
    var value: NSAttributedString
}

extension SystemGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: SystemGroup) -> Bool {
        self == source
    }
}

struct MessageGroup: Hashable {
    
    var id: String
    var title: String
    var type: MessageType
    
    init(id: String, title: String, type: MessageType) {
        self.id = id
        self.title = title
        self.type = type
    }
    
}

extension MessageGroup: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: MessageGroup) -> Bool {
        self == source
    }
}

struct AttachInfo: Hashable {
    
    enum ReadedStatus: Hashable {
        case signalReaded(_ readed: Bool)
        case groupReaded(_ readed: Bool, _ allReaded: Bool)
    }
    
    var readedStatus: ReadedStatus = .signalReaded(false)
    var text: String = ""
}

extension AttachInfo: Differentiable {
    public var differenceIdentifier: Int {
        readedStatus.hashValue
    }
    
    public func isContentEqual(to source: AttachInfo) -> Bool {
        self == source
    }
}

struct MessageEx: Hashable, Codable {
    var isFace: Bool = false
}

struct TextMessageSource: Hashable {
    var text: String
    var type: TextMessageType = .text
    private(set) var attributedText: NSAttributedString?
    
    init(text: String, type: TextMessageType = .text) {
        self.text = text
        self.type = type
        
        attributedText = text.addHyberLink()
    }
}

struct MediaMessageSource: Hashable {
    
    struct Info: Hashable {
        var url: URL!
        var relativePath: String?
        var size: CGSize = CGSize(width: 120, height: 120)
        
        static func == (lhs: Info, rhs: Info) -> Bool {
            lhs.url == rhs.url && lhs.relativePath == rhs.relativePath
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
            hasher.combine(relativePath)
        }
    }
    
    var image: UIImage?
    var source: Info
    var thumb: Info?
    var duration: Int?
    var fileSize: Int?
    var ex: MessageEx?
}

struct FileMessageSource: Hashable {
    var url: URL!
    var length: Int = 0
    var name: String?
    var relativePath: String?
}

struct CardMessageSource: Hashable {
    var user: User
}

struct LocationMessageSource: Hashable {
    var url: URL?
    var name: String?
    var address: String?
    
    var desc: String = ""
    var latitude: Double = 0 
    var longitude: Double = 0 
}

struct FaceMessageSource: Hashable {
    var localPath: String?
    var url: URL
    var index: Int
}

struct NoticeMessageSource: Hashable {
    
    enum MixType: Int {
        case text = 0
        case textImage = 1
        case textVideo = 2
        case textFile = 3
    }
    
    private(set) var type: NoticeType
    private(set) var detail: String?
    private(set) var avatar: String?
    private(set) var title: String?
    private(set) var text: String?
    private(set) var snapshotUrl: String?
    private(set) var mixType: MixType = .text
    private(set) var derictURL: String?
    private(set) var height: CGFloat?
    private(set) var width: CGFloat?
    
    init(type: NoticeType, detail: String? = nil) {
        self.type = type
        self.detail = detail
        
        guard let detail else { return }
        
        if let value = try? JSONSerialization.jsonObject(with: detail.data(using: .utf8)!, options: .mutableContainers) as? [String: Any] {
            avatar = value["notificationFaceURL"] as? String
            title = value["notificationName"] as? String
            text = value["text"] as? String
            mixType = MixType(rawValue: value["mixType"] as! Int) ?? .text
            derictURL = value["url"] as? String
            
            if let picture = value["pictureElem"] as? [String: Any], let s = picture["sourcePicture"] as? [String: Any] {
                snapshotUrl = s["url"] as? String
                height = s["height"] as? CGFloat
                width = s["width"] as? CGFloat
            }
        }
    }
}

struct CustomMessageSource: Hashable {
    public enum CustomMessageType: Int {
        case call = 901 
        case customEmoji = 902 // emoji
        case tagMessage = 903 
        case moments = 904 
        case meeting = 905 
        case blockedByFriend = 910 
        case deletedByFriend = 911 
    }

    var data: String?
    private(set) var attributedString: NSAttributedString?
}

extension CustomMessageSource {
    public var value: [String: Any]? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            return obj["data"] as? [String: Any]
        }
        
        return nil
    }
    
    public var type: CustomMessageType? {
        if let data = data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as! [String: Any]
            let t = obj["customType"] as! Int
            
            return CustomMessageType(rawValue: t)
        }
        
        return nil
    }
}

struct Message: Hashable {
    
    indirect enum Data: Hashable {
        
        case text(TextMessageSource)
        
        case attributeText(NSAttributedString)
        
        case url(URL, isLocallyStored: Bool)
        
        case image(MediaMessageSource, isLocallyStored: Bool)
        
        case video(MediaMessageSource, isLocallyStored: Bool) 
        
        case audio(MediaMessageSource, isLocallyStored: Bool)
        
        case file(FileMessageSource, isLocallyStored: Bool) 
        
        case card(CardMessageSource)
        
        case location(LocationMessageSource)
                
        case notice(NoticeMessageSource)
        
        case custom(CustomMessageSource)
        
        case face(FaceMessageSource, isLocallyStored: Bool)
        
        case none
    }
    
    var id: String
    
    var date: Date
    
    var contentType: MessageRawType
    
    var sessionType: MessageSessionRawType
    
    var data: Data
    
    var owner: User
    
    var type: MessageType
    
    var status: MessageStatus = .sending
    
    var isSelected: Bool = false 
    
    var isAnchor: Bool = false
}

extension Message {
    func getSummary() -> String? {
        var abstruct: String?
        
        switch data {
        case .text(let source):
            abstruct = source.type == .notice ? "[公告]" : source.text
        case .attributeText(let value):
            abstruct = value.string
        case .url(_, isLocallyStored: let isLocallyStored):
            abstruct = "[链接]".innerLocalized()
        case .image(_, isLocallyStored: let isLocallyStored):
            abstruct = "[图片]".innerLocalized()
        case .video(_, isLocallyStored: let isLocallyStored):
            abstruct = "[视频]".innerLocalized()
        case .audio(_, isLocallyStored: let isLocallyStored):
            abstruct = "[语音]".innerLocalized()
        case .file(_, isLocallyStored: let isLocallyStored):
            abstruct = "[文件]".innerLocalized()
        case .card(_):
            abstruct = "[名片]"
        case .location(_):
            abstruct = "[定位]"
            
        default:
            break
        }
        
        return abstruct
    }
}

extension Message: Differentiable {
    
    public var differenceIdentifier: Int {
        id.hashValue
    }
    
    public func isContentEqual(to source: Message) -> Bool {
        self == source
    }
}
