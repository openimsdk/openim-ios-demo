#
# Be sure to run `pod lib lint OIMUIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https:#

Pod::Spec.new do |s|
  s.name             = 'OUICore'
  s.version          = '0.0.1'
  s.summary          = '配合OpenIMSDK的iOS原生界面'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  OpenIM：由前微信技术专家打造的基于 Go 实现的即时通讯（IM）项目，iOS版本IM SDK 可以轻松替代第三方IM云服务，打造具备聊天、社交功能的app。
                       DESC

  s.homepage         = 'https://www.rentsoft.cn/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rentsoft' => 'https://www.rentsoft.cn/' }
  s.source           = { :git => 'git@github.com:OIMUI/OUICore.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.0'
  
  s.source_files = 'OUICore/Classes/**/*'
  s.resource_bundles = {
    'OIMUIResource' => ['OUICore/Assets/OIMUIResource.bundle/**/*'],
    'OIMUIEmoji' => ['OUICore/Assets/OIMUIEmoji.bundle/*'],
  }

  s.static_framework = true

  s.dependency 'OpenIMSDK', '3.8.3+3'
  s.dependency 'SnapKit', '~> 4.0'
  s.dependency 'RxSwift', '~> 6.5'
  s.dependency 'RxCocoa', '~> 6.0'
  s.dependency 'RxKeyboard', '~> 2.0'
  s.dependency 'RxDataSources'
  s.dependency 'Kingfisher', '8.0.1'
  s.dependency 'lottie-ios', '~> 3.0'
  s.dependency 'ProgressHUD'
  s.dependency 'Localize-Swift', '~> 3.2'
  s.dependency 'Alamofire', '4.9.1'
  s.dependency 'ZLPhotoBrowser'
  s.dependency 'YYText'
  s.dependency 'KTVHTTPCache', '3.0.2'
end
