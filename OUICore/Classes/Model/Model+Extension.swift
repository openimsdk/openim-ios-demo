
import Foundation
import YYText

public enum ContactItemType: Codable {
    case user
    case group
}

public struct ContactInfo: Codable {
    public let ID: String?
    public let name: String?
    public let faceURL: String?
    public let sub: String?
    public var type: ContactItemType
    public var createTime: Int
    
    public init(ID: String? = nil, name: String? = nil, faceURL: String? = nil, sub: String? = nil, type: ContactItemType = .user, createTime: Int = 0) {
        self.ID = ID
        self.name = name
        self.faceURL = faceURL
        self.sub = sub
        self.type = type
        self.createTime = createTime
    }
}

extension ContactInfo {
    public func toSimplePublicUserInfo() -> PublicUserInfo {
        PublicUserInfo(userID: ID!, nickname: name, faceURL: faceURL)
    }
}

fileprivate let nameAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.f14,
    NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
    NSAttributedString.Key.underlineStyle: 0
]

fileprivate let contentAttributes: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key.font: UIFont.f14,
    NSAttributedString.Key.foregroundColor: UIColor.c8E9AB0,
    NSAttributedString.Key.underlineStyle: 0
]

fileprivate func actionNameAttributes(userID: String) -> [NSAttributedString.Key: Any] {
    [   NSAttributedString.Key.link: "\(linkSchme)\(userID)",
        NSAttributedString.Key.font: UIFont.f14,
        NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
        NSAttributedString.Key.underlineStyle: 0
    ]
}

fileprivate let actionSendFriendReqestAttributes: [NSAttributedString.Key: Any] =
    [   NSAttributedString.Key.link: "\(sendFriendReqSchme)",
        NSAttributedString.Key.font: UIFont.f14,
        NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
        NSAttributedString.Key.underlineStyle: 0
    ]

public let linkSchme = "link://"
public let sendFriendReqSchme = "sendFriendReq://"

extension MessageInfo {
    public func getAbstruct() -> String? {
        switch contentType {
        case .text:
            return content
        case .quote:
            return quoteElem?.text
        case .at:
            return atTextElem?.atText
        default:
            return contentType.abstruct
        }
    }
}


extension MessageContentType {
    public var abstruct: String {
        switch self {
        case .image:
            return "[\("picture".innerLocalized())]"
        case .audio:
            return "[\("voice".innerLocalized())]"
        case .video:
            return "[\("video".innerLocalized())]"
        case .file:
            return "[\("file".innerLocalized())]"
        case .card:
            return "[\("carte".innerLocalized())]"
        case .location:
            return "[\("location".innerLocalized())]"
        case .merge:
            return "[\("mergeForward".innerLocalized())]"
        case .face:
            return "[\("emoji".innerLocalized())]"
        case .custom:
            return "[\("custom".innerLocalized())]"
        default:
            return ""
        }
    }
}

extension GroupMemberInfo {
    public var isSelf: Bool {
        return userID == IMController.shared.uid
    }
    
    public var joinWay: String {
        switch joinSource {
        case .invited:
            return "\(inviterUserName ?? "")\("邀请加入".innerLocalized())"
        case .search:
            return "搜索加入".innerLocalized()
        case .QRCode:
            return "扫描二维码加入".innerLocalized()
        }
    }
    
    public var roleLevelString: String {
        switch roleLevel {
        case .admin:
            return "groupAdmin".innerLocalized()
        case .owner:
            return "groupOwner".innerLocalized()
        default:
            return ""
        }
    }
    
    public var isOwnerOrAdmin: Bool {
        return roleLevel == .owner || roleLevel == .admin
    }
}

extension GroupInfo {
    public func needVerificationText() -> String {
        
        if (needVerification == .allNeedVerification) {
            return "needVerification".innerLocalized()
        } else if (needVerification == .directly) {
            return "allowAnyoneJoinGroup".innerLocalized()
        }
        return "inviteNotVerification".innerLocalized()
    }
}

extension UserStatusInfo {
    public var statusDesc: String {
        if status == 0 {
            return "offline".innerLocalized()
        }
        let des = platformIDs!.compactMap { platform in
            switch (platform) {
            case 1:
                return "iOS"
            case 2:
                return "Android"
            case 3:
                return "Windows"
            case 4:
                return "Mac"
            case 5:
                return "Web"
            case 6:
                return "mini_web"
            case 7:
                return "Linux"
            case 8:
                return "Android_pad"
            case 9:
                return "iPad"
            default:
                return nil
            }
        }
        return des.joined(separator: "/") + "在线".innerLocalized()
    }
}

extension FaceElem {
    public var url: String? {
        if let data {
            let obj = try! JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as? [String: Any]
            let t = obj?["url"] as? String
            
            return t
        }
        
        return nil
    }
}

extension AtTextElem {
    public var atText: String {
        var temp = text!
        atUserList?.forEach({ userID in
            if let userName = atUsersInfo?.first(where: { $0.atUserID == userID })?.groupNickname {
                temp = temp.replacingOccurrences(of: "@\(userID)",
                                                 with: "@\(userName)")
            }
        })
        
        return temp
    }
    
    private func actionNameAttributes(userID: String) -> [NSAttributedString.Key: Any] {
        [   NSAttributedString.Key.link: "link://\(userID)",
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.underlineStyle: 0
        ]
    }
    
    private func replaceUserIDToName(attrString: NSMutableAttributedString, userID: String, to userName: String) -> NSAttributedString {
        let range = (attrString.string as NSString).range(of: "@\(userID)")
        
        if range.location != NSNotFound {
            let rName = "@\(userName)"
                        
            attrString.beginEditing()
            attrString.replaceCharacters(in: range, with: rName)
            let uID = userID == IMController.shared.atAllTag() ? "" : userID
            attrString.addAttributes(actionNameAttributes(userID: uID), range: NSMakeRange(range.location, rName.count))
            attrString.endEditing()

            replaceUserIDToName(attrString: attrString, userID: userID, to: userName)
        }
        
        return attrString
    }
    
    public var atAttributeString: NSAttributedString {
        var attrText = NSAttributedString(string: text!)
        
        if let atUserList, let text, let atUsersInfo {
            attrText = createAttrString(baseString: text, users: atUsersInfo)
        }
        
        return attrText
    }
    
    func createAttrString(baseString inputString: String, users: [AtInfo]) -> NSMutableAttributedString {
        
        var tempText = inputString
        
        for user in users {
            let nickname = user.groupNickname ?? user.atUserID!
            
            tempText.replace("@\(user.atUserID!)", withString: "@\(nickname)")
        }
        
        let tempAttributedText = tempText.addHyberLink() ?? NSAttributedString(string: tempText)
        let content = NSMutableAttributedString(attributedString: tempAttributedText)
        
        for user in users {
            let nickname = user.groupNickname ?? user.atUserID!
            
            var currentIndex = tempText.startIndex
            while currentIndex < tempText.endIndex {
                if let range = tempText[currentIndex...].range(of: "@\(nickname)", options: .literal) {
                    let nsRange = NSRange(range, in: tempText)
                    content.addAttributes(actionNameAttributes(userID: user.atUserID!), range: nsRange)
                    currentIndex = range.upperBound
                } else {
                    currentIndex = tempText.index(after: currentIndex)
                }
            }
        }
        
        return content
    }
}

extension MessageInfo {
    public func getSummary() -> String {
        return MessageHelper.getSummary(by: self)
    }
    
    public func systemNotification(highlight: Bool = true) -> NSAttributedString? {
        
        func createAttrString(baseString inputString: String, users: [GroupMemberInfo]) -> NSMutableAttributedString {
            let content = NSMutableAttributedString(string: inputString, attributes: contentAttributes)
            
            for user in users {
                let nickname = user.isSelf ? "you".innerLocalized() : user.nickname ?? user.userID!
                
                var currentIndex = inputString.startIndex
                while currentIndex < inputString.endIndex {
                    if let range = inputString[currentIndex...].range(of: nickname, options: .literal) {
                        let nsRange = NSRange(range, in: inputString)
                        content.addAttributes(highlight ? actionNameAttributes(userID: user.userID!) : contentAttributes, range: nsRange)
                        currentIndex = range.upperBound
                    } else {
                        currentIndex = inputString.index(after: currentIndex)
                    }
                }
            }
            
            return content
        }
        
        func formatUsersName(users: [GroupMemberInfo]) -> String {
            users.compactMap({ $0.userID == IMController.shared.uid ? "you".innerLocalized() : ($0.nickname ?? $0.userID) }).joined(separator: "、")
        }
        
        func spaceString() -> NSAttributedString {
            return NSAttributedString(string: " ", attributes: contentAttributes)
        }
        
        func opUserName(message: MessageInfo) -> String {
            guard let opUser = message.notificationElem?.opUser else { return "" }
            
            if opUser.userID == IMController.shared.uid {
                return "you".innerLocalized()
            } else {
                return opUser.nickname ?? ""
            }
        }

        var result: NSMutableAttributedString?
        
        switch contentType {
        case .friendAppApproved:
            
            result = NSMutableAttributedString(string: "friendAddedNtf".innerLocalized(), attributes: contentAttributes)
        case .memberQuit:

            if let notificationElem, let user = notificationElem.quitUser {
                
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (user.nickname ?? user.userID!)
                let str = "quitGroupNtf".innerLocalizedFormat(arguments: nickname)
                
                result = createAttrString(baseString: str, users: [user])
            }
        case .memberEnter:
            
            if let notificationElem, let user = notificationElem.entrantUser {
                
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (user.nickname ?? user.userID!)
                let str = "joinGroupNtf".innerLocalizedFormat(arguments: nickname)
                
                result = createAttrString(baseString: str, users: [user])
            }
        case .memberKicked:
            
            if let notificationElem, let users = notificationElem.kickedUserList, let opUser = notificationElem.opUser {
                let opNickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)

                let nicknames = formatUsersName(users: users)
                let str = "kickedGroupNtf".innerLocalizedFormat(arguments: nicknames, opNickname)
                
                result = createAttrString(baseString: str, users: users + [opUser])
            }
        case .memberInvited:
            
            if let notificationElem, let users = notificationElem.invitedUserList, let opUser = notificationElem.opUser {
                let opNickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let nicknames = formatUsersName(users: users)
                let str = "invitedJoinGroupNtf".innerLocalizedFormat(arguments: opNickname, nicknames)
                
                result = createAttrString(baseString: str, users: users + [opUser])
            }
        case .groupCreated:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let str = "createGroupNtf".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .groupInfoSet:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let str = "editGroupInfoNtf".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .revoke:
            
            var revoker = ""
            var beRevoker = ""
            
            if revokedInfo.sessionType == .c2c {
                revoker = revokedInfo.revokerIsSelf ? "you".innerLocalized() : revokedInfo.revokerNickname ?? ""
            } else {
                revoker = revokedInfo.revokerIsSelf ? "you".innerLocalized() : revokedInfo.revokerNickname!
                beRevoker = (revokedInfo.revokerIsSelf && revokedInfo.sourceMessageSendIDIsSelf) || 
                revokedInfo.revokerID == revokedInfo.sourceMessageSendID
                ? "" : 
                (revokedInfo.sourceMessageSendIDIsSelf ? "you".innerLocalized() : revokedInfo.sourceMessageSenderNickname!)
            }
                            
            let revokerInfo = GroupMemberInfo()
            revokerInfo.userID = revokedInfo.revokerID
            revokerInfo.nickname = revoker
            
            if !beRevoker.isEmpty {
                let beRevokerInfo = GroupMemberInfo()
                beRevokerInfo.userID = revokedInfo.revokerID
                beRevokerInfo.nickname = beRevoker
                
                let str = "aRevokeBMsg".innerLocalizedFormat(arguments: revoker, beRevoker)
                result = createAttrString(baseString: str, users: [revokerInfo, beRevokerInfo])
            } else {
                let str = "revokeMsg".innerLocalizedFormat(arguments: revoker)
                result = createAttrString(baseString: str, users: [revokerInfo])
            }
        case .conversationNotification:
            result = NSMutableAttributedString(string: "enabledNoDisturb".innerLocalized(), attributes: contentAttributes)
            
        case .conversationNotNotification:
            result = NSMutableAttributedString(string: "disableNoDisturb".innerLocalized(), attributes: contentAttributes)

        case .dismissGroup:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let str = "dismissGroupNtf".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .typing:
            return nil
        case .privateMessage:
            
            if let value = notificationElem?.detailObject {
                let enable = value["isPrivate"] as? Bool
                result = NSMutableAttributedString(string: enable == true ?
                                                 "openPrivateChatNtf".innerLocalized() :
                                                 "closePrivateChatNtf".innerLocalized(),
                                                 attributes: contentAttributes)
            }

        case .groupMuted:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let str = "muteGroupNtf".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .groupCancelMuted:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                
                let str = "muteCancelGroupNtf".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .groupOwnerTransferred:
            
            if let notificationElem, let opUser = notificationElem.opUser, let newOwner = notificationElem.groupNewOwner {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                let newNickname = newOwner.isSelf ? "you".innerLocalized() : (newOwner.nickname ?? newOwner.userID!)
                
                let str = "transferredGroupNtf".innerLocalizedFormat(arguments: nickname, newNickname)
                result = createAttrString(baseString: str, users: [opUser, newOwner])
            }
        case .groupSetName:
            
            if let notificationElem, let opUser = notificationElem.opUser, let group = notificationElem.group {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)

                let str = "whoModifyGroupName".innerLocalizedFormat(arguments: nickname, group.groupName ?? "")
                result = createAttrString(baseString: str, users: [opUser])
            }
        case .groupAnnouncement:
            
            if let notificationElem, let notification = notificationElem.group?.notification {
                result = NSMutableAttributedString(string: notification)
            }
        case .oaNotification:

            if let detail = notificationElem?.detailObject {
                result = NSMutableAttributedString(string: "\(detail["text"] ?? "")", attributes: contentAttributes)
            }
        case .groupMemberMuted:
            
            if let notificationElem,
                let opUser = notificationElem.opUser,
                let detail = notificationElem.detailObject as? [String: Any],
                let mutedUser = detail["mutedUser"] as? [String: Any],
                let mutedSeconds = detail["mutedSeconds"] as? Int {
                
                var dispalySeconds = FormatUtil.getMutedFormat(of: mutedSeconds)
                let muted = GroupMemberInfo()
                muted.userID = mutedUser["userID"] as! String
                muted.nickname = mutedUser["nickname"] as? String
                
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                let mutedNickname = muted.isSelf ? "you".innerLocalized() : (muted.nickname ?? muted.userID!)
                
                let str = "muteMemberNtf".innerLocalizedFormat(arguments: mutedNickname, nickname, dispalySeconds)
                result = createAttrString(baseString: str, users: [muted, opUser])
            }
        case .groupMemberCancelMuted:
            
            if let notificationElem,
                let opUser = notificationElem.opUser,
                let detail = notificationElem.detailObject as? [String: Any],
                let mutedUser = detail["mutedUser"] as? [String: Any] {
                
                let muted = GroupMemberInfo()
                muted.userID = mutedUser["userID"] as! String
                muted.nickname = mutedUser["nickname"] as? String
                
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)
                let mutedNickname = muted.isSelf ? "you".innerLocalized() : (muted.nickname ?? muted.userID!)

                let str = "muteCancelMemberNtf".innerLocalizedFormat(arguments: mutedNickname, nickname)
                result = createAttrString(baseString: str, users: [muted, opUser])
            }
        case .groupMemberInfoSet:
            
            if let notificationElem, let opUser = notificationElem.opUser {
                let nickname = notificationElem.opUserIsMe ? "you".innerLocalized() : (opUser.nickname ?? opUser.userID!)

                let str = "editedMemberInfo".innerLocalizedFormat(arguments: nickname)
                result = createAttrString(baseString: str, users: [opUser])
            }
        default:
            result = NSMutableAttributedString(string: "\("unsupportedMessage".innerLocalized()) \(contentType)", attributes: contentAttributes)
        }
        
        return result
    }
    
    public var customMessageAbstruct: String {
        guard let type = customElem?.type else {
            return "unsupportedMessage".innerLocalized()
        }
        
        switch type {
        case .call, .callingInvite, .callingAccept, .callingReject, .callingCancel, .callingHungup:
            if let value = customElem?.value() {
                let isVideo = value["type"] as? String == "video"
                let tips = isVideo ? "callVideo".innerLocalized() : "callVoice".innerLocalized()
                
                return "[\(tips)]"
            }
            return "[" + "音视频".innerLocalized() + "]"
        case .customEmoji:
            return "[\("emoji".innerLocalized())]"
        case .tagMessage:
            return "[\("tagGroup".innerLocalized())]"
        case .blockedByFriend:
            return "blockedByFriendHint".innerLocalized()
        case .deletedByFriend:
            return "deletedByFriendHint".innerLocalizedFormat(arguments: "sendFriendVerification".innerLocalized())
        case .moments:
            return "[" + "朋友圈".innerLocalized() + "]"
        case .meeting:
            return "[\("meetingInvitation".innerLocalized())]"
        }
    }
    
    public var customMessageDetailAttributedString: NSAttributedString {
        
        guard contentType == .custom,
                let type = customElem?.type,
                let value = customElem?.value() else { return NSAttributedString() }
        
        var str = NSMutableAttributedString()
        
        switch type {
        case .blockedByFriend:
            
            str = NSMutableAttributedString(string: "blockedByFriendHint".innerLocalized(), attributes: contentAttributes)
        case .deletedByFriend:
            let addFirendStr = "sendFriendVerification".innerLocalized()
            let baseStr = "deletedByFriendHint".innerLocalizedFormat(arguments: addFirendStr)
            str = NSMutableAttributedString(string: baseStr, attributes: contentAttributes)
                
            var currentIndex = baseStr.startIndex
            while currentIndex < baseStr.endIndex {
                if let range = baseStr[currentIndex...].range(of: addFirendStr, options: .literal) {
                    let nsRange = NSRange(range, in: baseStr)
                    str.addAttributes(actionSendFriendReqestAttributes, range: nsRange)
                    currentIndex = range.upperBound
                } else {
                    currentIndex = baseStr.index(after: currentIndex)
                }
            }
            
        case .call:
            
            let isVideo = value["type"] as? String == "video"
            
            if let image = UIImage(nameInBundle: isVideo ? "call_video_msg" : "call_voice_msg"),
               let attachment = NSMutableAttributedString.yy_attachmentString(withEmojiImage: image, fontSize: 18) {
                str.append(attachment)
            }
            
            if let msg = value["msg"] as? String {
                str.append(NSAttributedString(string: msg, attributes: [.font: UIFont.f17]))
            }
            
        case .meeting:
            
            let inviterNickname = value["inviterNickname"] as? String
            let subject = value["subject"] as? String
            let start = Date.timeString(timeInterval: (value["start"] as! TimeInterval) * 1000)
            let duration = value["duration"] as! Int
            let ID = value["id"] as! String
            
            let space = NSAttributedString(string: " \n", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8)])
            
            if let image = UIImage(nameInBundle: "chat_live_room_icon"),
               let imageAttachment = NSMutableAttributedString.yy_attachmentString(withEmojiImage: image, fontSize: UIFont.f17.pointSize) {
                str.append(imageAttachment)
            }
            let text = " \(subject ?? "meetingInitiatorIs".innerLocalizedFormat(arguments: inviterNickname ?? ""))" +
            "\n • \("meetingStartTimeIs".innerLocalizedFormat(arguments: start))" +
            "\n • \("meetingDurationIs".innerLocalizedFormat(arguments: formatTime(seconds: duration)))" +
            "\n • \("meetingNoIs".innerLocalizedFormat(arguments: ID))"
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8
            paragraphStyle.lineBreakMode = .byWordWrapping

            str.append(NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                                                       NSAttributedString.Key.font: UIFont.f17]))
            
            let paragraphStyle2 = NSMutableParagraphStyle()
            paragraphStyle2.lineSpacing = 16
            paragraphStyle2.alignment = .center
            
            let tips = NSAttributedString(string: "\n\("enterMeeting".innerLocalized()) ",
                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.c0089FF,
                                                       NSAttributedString.Key.font: UIFont.f17,
                                                       NSAttributedString.Key.paragraphStyle: paragraphStyle2])
            
            str.append(tips)
            
            if let arrowImage = UIImage(nameInBundle: "common_blue_arrow_right_icon"),
               let arrowAttachment = NSMutableAttributedString.yy_attachmentString(withEmojiImage: arrowImage, fontSize: UIFont.f17.pointSize) {
                str.append(arrowAttachment)
            }
            
        default:
            break
        }
        
        return str
    }
    
    private func formatTime(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full

        if seconds >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }

        guard let formattedString = formatter.string(from: TimeInterval(seconds)) else {
            return ""
        }

        return formattedString
    }
}

extension ConversationInfo {
    public var summary: String? {
        return conversationType == .c2c ? latestMsg?.getSummary() : showName! + ":" + (latestMsg?.getSummary())!
    }
}

extension NotificationElem {
    var opUserIsMe: Bool {
        opUser?.userID == IMController.shared.uid
    }
}

extension GroupMemberInfo {
    public func toSimplePublicUserInfo() -> PublicUserInfo {
        PublicUserInfo(userID: userID!, nickname: nickname, faceURL: faceURL)
    }
}

extension FriendInfo {
    public var showName: String {
        return (remark != nil && remark!.count > 0) ? remark! : (nickname ?? userID!)
    }
}

extension PublicUserInfo {
    public func toFriendInfo() -> FriendInfo {
        FriendInfo(userID: userID!, nickname: nickname, faceURL: faceURL)
    }
    
    public func toUserInfo() -> UserInfo {
        UserInfo(userID: userID!, nickname: nickname, faceURL: faceURL)
    }
}

extension UserInfo {
    public func toFriendInfo() -> FriendInfo {
        FriendInfo(userID: userID!, nickname: nickname, faceURL: faceURL, remark: remark)
    }
}
