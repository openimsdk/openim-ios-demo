
import Foundation

public struct MessageHelper {
    
    private static let nameAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.font: UIFont.f14,
        NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
        NSAttributedString.Key.underlineStyle: 0
    ]

    private static let contentAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.font: UIFont.f14,
        NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0,
        NSAttributedString.Key.underlineStyle: 0
    ]
    
    private static func actionNameAttributes(userID: String) -> [NSAttributedString.Key: Any] {
        [   NSAttributedString.Key.link: "link://\(userID)",
            NSAttributedString.Key.font: UIFont.f14,
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.underlineStyle: 0
        ]
    }
    
    private static func actionReEditAttributes(messageID: String) -> [NSAttributedString.Key: Any] {
        [   NSAttributedString.Key.link: "reEdit://\(messageID)",
            NSAttributedString.Key.font: UIFont.f14,
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.underlineStyle: 0
        ]
    }

    public static func getAbstructOf(conversation: ConversationInfo, highlight: Bool = true) -> NSAttributedString {
        var abstruct = ""
        let message = conversation.latestMsg
        let isSingleChat = conversation.conversationType == .c2c
        let unreadCount = conversation.unreadCount
        let status = conversation.recvMsgOpt
        
        if status != .receive, unreadCount > 0 {
            let unreadDesc: String
            if unreadCount > 99 {
                unreadDesc = "99+"
            } else {
                unreadDesc = "nPieces".innerLocalizedFormat(arguments: unreadCount)
            }
            abstruct = "[\(unreadDesc)]"
        }
        
        guard let message else {
            return NSAttributedString(string: abstruct, attributes: contentAttributes)
        }

        var tmpAttr: NSAttributedString?
        let sender = message.senderNickname != nil && message.sessionType == .superGroup && !message.isMine ? message.senderNickname! + "：" : ""
        
        switch message.contentType {
        case .text:
            abstruct += sender
            abstruct += message.textElem?.content ?? ""
        case .image, .audio, .video, .file, .card, .location, .face, .merge:
            abstruct += sender
            abstruct += message.contentType.abstruct
            
            if message.contentType == .merge {
                abstruct += message.mergeElem?.title ?? ""
            }
        case .at:

            if let atElem = message.atTextElem {
                abstruct += sender
                abstruct += atElem.atText
            }
        case .quote:
            abstruct += sender
            abstruct += message.quoteElem?.text ?? ""
        case .privateMessage:
            abstruct += conversation.isPrivateChat ? "openPrivateChatNtf".innerLocalized() : "closePrivateChatNtf".innerLocalized()
        case .custom:
            abstruct += message.customMessageAbstruct
        default:
            tmpAttr = message.systemNotification(highlight: highlight)
        }
        
        abstruct = abstruct.replacingOccurrences(of: "\n", with: " ")
        
        var ret = NSMutableAttributedString(string: abstruct, attributes: contentAttributes)
        
        if let tmpAttr {
            ret.append(tmpAttr)
            ret.removeAttribute(NSAttributedString.Key.link, range: NSMakeRange(0, ret.length))
        }
        
        return ret
    }
    
    public static func getSummary(by message: MessageInfo) -> String {
   
        var abstruct = ""
        
        switch message.contentType {
        case .text:
            abstruct += message.textElem?.content ?? ""
        case .image, .audio, .video, .file, .card, .location, .face, .merge:
            abstruct += message.contentType.abstruct
        case .at:

            if let atElem = message.atTextElem {
                
                if atElem.isAtSelf {
                    abstruct += "[\("someoneMentionYou".innerLocalized())]"
                } else {
                    let names = atElem.atUsersInfo?.compactMap { $0.groupNickname } ?? []
                    var desc: String = ""
                    for name in names {
                        desc.append(name)
                        desc.append(" ")
                    }
                    abstruct += desc
                }
            }
        case .quote:
            abstruct += message.quoteElem?.text ?? ""
        case .custom:
            abstruct += message.customMessageAbstruct
        default:
            break
        }
        
        return abstruct
    }

    public static func getAudioMessageDisplayWidth(duration: Int) -> CGFloat {
        let duration = CGFloat(duration)
        let Lmin: CGFloat = 50

        let Lmax: CGFloat = kScreenWidth * 0.5
        var barLen: CGFloat = 0
        var barCanChangeLen: CGFloat = Lmax - Lmin
        var unitWidth: CGFloat = barCanChangeLen / 58

        switch duration {
        case 0 ..< 2:
            barLen = Lmin
        case 2 ..< 10:
            barLen = Lmin + (duration - 2) * unitWidth
        case 10 ..< 60:
            barLen = (Lmin + 10 * unitWidth) + (70 - duration) / 10 * unitWidth
        default:
            barLen = Lmax
        }
        return barLen
    }
    
    private static func getMidnightOf(date: Date) -> TimeInterval {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        let dateStr = formatter.string(from: date)
        let midnight = formatter.date(from: dateStr)
        return midnight?.timeIntervalSince1970 ?? 0
    }

    public static func convertList(timestamp_ms: Int) -> String {
        let current = TimeInterval(timestamp_ms / 1000)

        let date = Date(timeIntervalSince1970: current)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let zero = getMidnightOf(date: Date())
        let offset = zero - current
        let secondsPerDay: Double = 24 * 60 * 60

        var desc = ""
        if offset <= 0 {
            let now = Date().timeIntervalSince1970
            if fabs(now - current) < 3 * 60 {
                desc = "刚刚".innerLocalized()
            } else {
                desc = formatter.string(from: date)
            }
            return desc
        }

        if offset <= 1 * secondsPerDay {
            let m = formatter.string(from: date)
            desc = "昨天".innerLocalized() + " " + "\(m)"
            return desc
        }

        let calendar = Calendar.current
        if offset <= 7 * secondsPerDay {
            let flag = Calendar.Component.weekday
            let currentCompo = calendar.dateComponents([flag], from: date)
            guard let week = currentCompo.weekday else {
                return desc
            }
            switch week {
            case 1: desc = "星期日".innerLocalized()
            case 2: desc = "星期一".innerLocalized()
            case 3: desc = "星期二".innerLocalized()
            case 4: desc = "星期三".innerLocalized()
            case 5: desc = "星期四".innerLocalized()
            case 6: desc = "星期五".innerLocalized()
            case 7: desc = "星期日".innerLocalized()
            default:
                break
            }
            return desc
        }

        formatter.dateFormat = "yyyy/MM/dd"
        desc = formatter.string(from: date)
        return desc
    }
}
