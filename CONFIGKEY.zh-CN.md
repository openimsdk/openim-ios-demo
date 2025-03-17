
# 常见功能配置指南

- [离线推送功能](#离线推送功能)
- [地图功能](#地图功能)

## 离线推送功能

目前使用的是集成方案。

### 客户端配置

#### 1. 中国大陆地区使用个推（[Getui](https://getui.com/)）

###### 在[Getui](https://getui.com/)的集成指南，配置iOS。

**iOS 平台配置：**
根据[其文档](https://docs.getui.com/getui/mobile/ios/overview/)做好相应的iOS配置。然后在代码中找到以下文件并修改对应的 iOS侧Key：

- **[AppDelegate.swift](Example/OpenIMSDKUIKit/AppDelegate.swift)**

```swift
  fileprivate let kGtAppId = ""
  fileprivate let kGtAppKey = ""
  fileprivate let kGtAppSecret = ""
```

#### 2. 海外地区使用 [FCM（Firebase Cloud Messaging）](https://firebase.google.com/docs/cloud-messaging)

根据 [FCM](https://firebase.google.com/docs/cloud-messaging) 的集成指南，替换以下文件：

- **[GoogleService-Info.plist](Example/OpenIMSDKUIKit/GoogleService-Info.plist)**（iOS 平台）

### 离线推送横幅设置

目前SDK的设计是直接由客户端控制推送横幅的展示内容。发送消息时，设置入参[offlinePushInfo](https://github.com/openimsdk/openim-ios-demo/blob/fd130e9282d582f6681f5e905b61e8ba02e398b6/OUICore/Classes/Core/IMController.swift#L826)：

```swift
  let offlinePushInfo = OfflinePushInfo(
    title: "填写标题",
    desc: "填写描述信息，例如消息内容",
  );
  // 如果不自定义offlinePushInfo，则title默认为app名称，desc默认为为“你收到了一条新消息”
```

根据实际需求，完成对应的客户端和服务端配置后即可启用离线推送功能。

---

## 地图功能

### 配置指南

需要配置对应的 AMap Key。具体请参考 [AMap 文档](https://lbs.amap.com/)，工程中的代码需要修改以下 Key：

- **[webKey](https://github.com/openimsdk/openim-ios-demo/blob/fd130e9282d582f6681f5e905b61e8ba02e398b6/OUIIM/Classes/OIMUIChat/LocationViewController.swift#L16)**
- **[webServerKey](https://github.com/openimsdk/openim-ios-demo/blob/fd130e9282d582f6681f5e905b61e8ba02e398b6/OUIIM/Classes/OIMUIChat/LocationViewController.swift#L17)**

```swift
  fileprivate let webKey = "your-web-key"
  fileprivate let webServerKey = "your-web-server-key"
```

完成配置后即可启用地图功能。
