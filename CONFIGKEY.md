# Common function configuration guide

- [Offline push function](#Offline push function)

- [Map function](#Map function)

## Offline push function

Currently using the integrated solution.

### Client configuration

#### 1. Use Getui (https://getui.com/) in mainland China

###### Configure iOS in the integration guide of Getui.

**iOS platform configuration:**
Make the corresponding iOS configuration according to [its documentation](https://docs.getui.com/getui/mobile/ios/overview/). Then find the following files in the code and modify the corresponding iOS side key:

- **[AppDelegate.swift](Example/OpenIMSDKUIKit/AppDelegate.swift)**

```swift
  fileprivate let kGtAppId = ""
  fileprivate let kGtAppKey = ""
  fileprivate let kGtAppSecret = ""
```

#### 2. Use [FCM (Firebase Cloud Messaging)](https://firebase.google.com/docs/cloud-messaging) in overseas regions

According to the integration guide of [FCM](https://firebase.google.com/docs/cloud-messaging), replace the following files:

- **[GoogleService-Info.plist](Example/OpenIMSDKUIKit/GoogleService-Info.plist)** (iOS platform)

### Offline push banner settings

The current SDK design is that the display content of the push banner is directly controlled by the client. When sending a message, set the input parameter [offlinePushInfo](https://github.com/openimsdk/openim-ios-demo/blob/b6057a6aeab0b766ada76241ba783fa819bb2e70/OUICore/Classes/Core/IMController.swift#L819):

```swift
  let offlinePushInfo = OfflinePushInfo(
  title: "Fill in the title",
  desc: "Fill in the description, such as the message content",
  );
  // If you do not customize offlinePushInfo, the title defaults to the app name, and the desc defaults to "You have received a new message"
```

According to actual needs, complete the corresponding client and server configurations to enable the offline push function.

---

## Map function

### Configuration guide

Need to configure the corresponding AMap Key. Please refer to [AMap Document](https://lbs.amap.com/) for details. The code in the project needs to modify the following Key:

- **[webKey](https://github.com/openimsdk/openim-ios-demo/blob/b6057a6aeab0b766ada76241ba783fa819bb2e70/OUIIM/Classes/OIMUIChat/LocationViewController.swift#L16)**
- **[webServerKey](https://github.com/openimsdk/openim-ios-demo/blob/b6057a6aeab0b766ada76241ba783fa819bb2e70/OUIIM/Classes/OIMUIChat/LocationViewController.swift#L17)**

```swift
  fileprivate let webKey = "your-web-key"
  fileprivate let webServerKey = "your-web-server-key"
```

Once the configuration is complete, you can enable the map function.