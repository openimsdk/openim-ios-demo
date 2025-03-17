

























import UIKit
import Foundation
import Photos

let version = "4.4.8.2"

public struct ZLPhotoBrowserWrapper<Base> {
    public let base: Base
    
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol ZLPhotoBrowserCompatible: AnyObject { }

public protocol ZLPhotoBrowserCompatibleValue { }

extension ZLPhotoBrowserCompatible {
    public var zl: ZLPhotoBrowserWrapper<Self> {
        get { ZLPhotoBrowserWrapper(self) }
        set { }
    }
    
    public static var zl: ZLPhotoBrowserWrapper<Self>.Type {
        get { ZLPhotoBrowserWrapper<Self>.self }
        set { }
    }
}

extension ZLPhotoBrowserCompatibleValue {
    public var zl: ZLPhotoBrowserWrapper<Self> {
        get { ZLPhotoBrowserWrapper(self) }
        set { }
    }
}

extension UIViewController: ZLPhotoBrowserCompatible { }
extension UIColor: ZLPhotoBrowserCompatible { }
extension UIImage: ZLPhotoBrowserCompatible { }
extension CIImage: ZLPhotoBrowserCompatible { }
extension PHAsset: ZLPhotoBrowserCompatible { }
extension UIFont: ZLPhotoBrowserCompatible { }
extension UIView: ZLPhotoBrowserCompatible { }
extension UIGraphicsImageRenderer: ZLPhotoBrowserCompatible { }

extension Array: ZLPhotoBrowserCompatibleValue { }
extension String: ZLPhotoBrowserCompatibleValue { }
extension CGFloat: ZLPhotoBrowserCompatibleValue { }
extension Bool: ZLPhotoBrowserCompatibleValue { }
