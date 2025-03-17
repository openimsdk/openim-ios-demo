<p align="center">
    <a href="https://openim.io">
        <img src="./docs/images/logo.jpg" width="60%" height="30%"/>
    </a>
</p>

# OpenIM iOS 💬💻

<p>
  <a href="https://docs.openim.io/">OpenIM Docs</a>
  •
  <a href="https://github.com/openimsdk/open-im-server">OpenIM Server</a>
  •
  <a href="https://github.com/openimsdk/open-im-sdk-ios">openim-sdk-ios</a>
  •
  <a href="https://github.com/openimsdk/openim-sdk-core">openim-sdk-core</a>
</p>

OpenIM provides an open-source Instant Messaging (IM) SDK for developers, serving as an alternative solution to cloud services like Twilio and Sendbird. With OpenIM, developers can build secure and reliable IM applications similar to WeChat, Zoom, and Slack.

This repository is based on the open-source version of the OpenIM SDK, offering an iOS IM application. You can use this application as a reference implementation of the OpenIM SDK.

<p align="center">
   <img src="./docs/images/preview1.jpeg" alt="Preview" width="32%"/>
   <span style="display: inline-block; width: 16px;"></span>
   <img src="./docs/images/preview2.jpeg" alt="Preview" width="32%"/>
</p>

## License :page_facing_up:

This repository is licensed under the GNU Affero General Public License Version 3 (AGPL-3.0) and is subject to additional terms. **Commercial use is prohibited**. For more details, see [here](./LICENSE).

## Development Environment

Before you start development, ensure that the following software is installed on your system:

- **Operating System**: macOS 14.6 or later
- **Xcode**: Version 15.4
- **Git**: For version control

Additionally, make sure you have [deployed](https://docs.openim.io/zh-Hans/guides/gettingStarted/dockerCompose) the latest version of the OpenIM Server. After deployment, you can compile the project and connect it to your server for testing.

## Supported Platforms

This application supports the following platforms:

| Platform      | Version               | Status |
| ------------- | --------------------- | ------ |
| **iOS**       | 13.0 and above        | ✅     |

### Notes

- **iOS**: Make sure your version meets the requirements to avoid compilation issues.

## Quick Start

Follow the steps below to set up your local development environment:

1. Clone the repository:

   ```bash
   git clone https://github.com/openimsdk/openim-ios-demo.git
   cd openim-ios-demo/Example
   ```

2. Install dependencies

   ```bash
   pod install
   ```
   2.1 If the installation fails and a message appears saying that a dependency was not found, please execute the following command to update the local CocoaPods repository list.
   ```bash
   pod repo update
   ```

3. Modify the configuration

     > If you have not changed the default server ports, update only the [defaultHost](https://github.com/openimsdk/open-im-ios-demo/blob/948cb89c11e046a2928708d6f22e5ff213deb2fe/Example/OpenIMSDKUIKit/AppDelegate.swift#L21) to your server IP.

   ```swift
   let defaultHost = "your-server-ip or your-domain";
   ```

4. open OpenIMSDKUIKit.xcworkspace to compile and run the program.

5. Start developing and testing! 🎉

## Audio/Video Calls

The open-source version supports one-to-one audio and video calls. You need to first deploy and configure the [server](https://github.com/openimsdk/chat/blob/main/HOW_TO_SETUP_LIVEKIT_SERVER.md). For multi-party audio/video calls or video conferencing, please contact us at [contact@openim.io](mailto:contact@openim.io).

## Build 🚀

 Click "Archive" to compile the IPA package.

## Features

### Description

| Feature Module             | Feature                                                                          | Status |
| -------------------------- | -------------------------------------------------------------------------------- | ------ |
| **Account Features**       | Phone number registration \ Email registration \ Verification code login         | ✅     |
|                            | View \ Edit personal information                                                 | ✅     |
|                            | Multi-language settings                                                          | ✅     |
|                            | Change password \ Forgot password                                                | ✅     |
| **Friend Features**        | Find \ Apply \ Search \ Add \ Delete friends                                     | ✅     |
|                            | Accept \ Reject friend requests                                                  | ✅     |
|                            | Friend notes                                                                     | ✅     |
|                            | Allow friend requests or not                                                     | ✅     |
|                            | Friend list \ Friend data real-time syncing                                      | ✅     |
| **Blocklist**              | Restrict messages                                                                | ✅     |
|                            | Real-time syncing of blocklist                                                   | ✅     |
|                            | Add \ Remove from blocklist                                                      | ✅     |
| **Group Features**         | Create \ Dismiss groups                                                          | ✅     |
|                            | Apply to join \ Invite to join \ Leave group \ Remove members                    | ✅     |
|                            | Group name / Avatar changes / Group data updates (notifications, real-time sync) | ✅     |
|                            | Invite members to group                                                          | ✅     |
|                            | Transfer group ownership                                                         | ✅     |
|                            | Group owner or admin approve join requests                                       | ✅     |
|                            | Search group members                                                             | ✅     |
| **Message Features**       | Offline messages                                                                 | ✅     |
|                            | Roaming messages                                                                 | ✅     |
|                            | Multi-end messages                                                               | ✅     |
|                            | Message history                                                                  | ✅     |
|                            | Message deletion                                                                 | ✅     |
|                            | Clear messages                                                                   | ✅     |
|                            | Copy messages                                                                    | ✅     |
|                            | Typing indicator in single chat                                                  | ✅     |
|                            | Do Not Disturb for new messages                                                  | ✅     |
|                            | Clear chat history                                                               | ✅     |
|                            | New members can view group chat history                                          | ✅     |
|                            | New message reminders                                                            | ✅     |
|                            | Text messages                                                                    | ✅     |
|                            | Image messages                                                                   | ✅     |
|                            | Video messages                                                                   | ✅     |
|                            | Emoji messages                                                                   | ✅     |
|                            | File messages                                                                    | ✅     |
|                            | Voice messages                                                                   | ✅     |
|                            | Contact card messages                                                            | ✅     |
|                            | Location messages                                                                | ✅     |
|                            | Custom messages                                                                  | ✅     |
| **Conversation**           | Pin conversation                                                                 | ✅     |
|                            | Mark conversation as read                                                        | ✅     |
|                            | Mute conversation                                                                | ✅     |
| **REST API**               | Authentication management                                                        | ✅     |
|                            | User management                                                                  | ✅     |
|                            | Relationship chain management                                                    | ✅     |
|                            | Group management                                                                 | ✅     |
|                            | Conversation management                                                          | ✅     |
|                            | Message management                                                               | ✅     |
| **Webhook**                | Group callbacks                                                                  | ✅     |
|                            | Message callbacks                                                                | ✅     |
|                            | Push callbacks                                                                   | ✅     |
|                            | Relationship callbacks                                                           | ✅     |
|                            | User callbacks                                                                   | ✅     |
| **Capacity & Performance** | 10,000 friends                                                                   | ✅     |
|                            | 100,000-member supergroup                                                        | ✅     |
|                            | Second-level syncing                                                             | ✅     |
|                            | Cluster deployment                                                               | ✅     |
|                            | Multi-device kick-out strategy                                                   |        |
| **Online Status**          | No mutual kick-out across all platforms                                          | ✅     |
|                            | Each platform can only log in with one device                                    | ✅     |
|                            | PC, Mobile, Pad, Web, Mini Program each can log in with one device               | ✅     |
|                            | PC not mutually kicked, only one device total for other platforms                | ✅     |
| **Audio/Video Call**       | One-to-one audio and video calls                                                 | ✅     |
| **File Storage**           | Supports private Minio deployment                                                | ✅     |
|                            | Supports public cloud services COS, OSS, Kodo, S3                                | ✅     |
| **Push**                   | Real-time online message push                                                    | ✅     |
|                            | Offline message push, supports Getui, Firebase                                   | ✅     |

For more advanced features, audio/video calls, or video conferences, please contact us at [contact@openim.io](mailto:contact@openim.io).

## Join Our Community :busts_in_silhouette:

- 🚀 [Join our Slack community](https://join.slack.com/t/openimsdk/shared_invite/zt-22720d66b-o_FvKxMTGXtcnnnHiMqe9Q)
- :eyes: [Join our WeChat group](https://openim-1253691595.cos.ap-nanjing.myqcloud.com/WechatIMG20.jpeg)
