























import UIKit


@objc public protocol ZLImageStickerContainerDelegate {
    @objc var selectImageBlock: ((UIImage) -> Void)? { get set }
    
    @objc var hideBlock: (() -> Void)? { get set }
    
    @objc func show(in view: UIView)
}

@objcMembers
public class ZLEditImageConfiguration: NSObject {
    private static let defaultColors: [UIColor] = [
        .white,
        .black,
        .zl.rgba(249, 80, 81),
        .zl.rgba(248, 156, 59),
        .zl.rgba(255, 195, 0),
        .zl.rgba(145, 211, 0),
        .zl.rgba(0, 193, 94),
        .zl.rgba(16, 173, 254),
        .zl.rgba(16, 132, 236),
        .zl.rgba(99, 103, 240),
        .zl.rgba(127, 127, 127)
    ]
    
    private var pri_tools: [ZLEditImageConfiguration.EditTool] = ZLEditImageConfiguration.EditTool.allCases



    public var tools: [ZLEditImageConfiguration.EditTool] {
        get {
            if pri_tools.isEmpty {
                return ZLEditImageConfiguration.EditTool.allCases
            } else {
                return pri_tools
            }
        }
        set {
            pri_tools = newValue
        }
    }


    public var tools_objc: [Int] = [] {
        didSet {
            tools = tools_objc.compactMap { ZLEditImageConfiguration.EditTool(rawValue: $0) }
        }
    }
    
    private var pri_drawColors = ZLEditImageConfiguration.defaultColors

    public var drawColors: [UIColor] {
        get {
            if pri_drawColors.isEmpty {
                return ZLEditImageConfiguration.defaultColors
            } else {
                return pri_drawColors
            }
        }
        set {
            pri_drawColors = newValue
        }
    }

    public var defaultDrawColor: UIColor = .zl.rgba(249, 80, 81)
    
    private var pri_clipRatios: [ZLImageClipRatio] = [.custom]

    public var clipRatios: [ZLImageClipRatio] {
        get {
            if pri_clipRatios.isEmpty {
                return [.custom]
            } else {
                return pri_clipRatios
            }
        }
        set {
            pri_clipRatios = newValue
        }
    }
    
    private var pri_textStickerTextColors: [UIColor] = ZLEditImageConfiguration.defaultColors

    public var textStickerTextColors: [UIColor] {
        get {
            if pri_textStickerTextColors.isEmpty {
                return ZLEditImageConfiguration.defaultColors
            } else {
                return pri_textStickerTextColors
            }
        }
        set {
            pri_textStickerTextColors = newValue
        }
    }

    public var textStickerDefaultTextColor = UIColor.white

    public var textStickerDefaultFont: UIFont?
    
    private var pri_filters: [ZLFilter] = ZLFilter.all

    public var filters: [ZLFilter] {
        get {
            if pri_filters.isEmpty {
                return ZLFilter.all
            } else {
                return pri_filters
            }
        }
        set {
            pri_filters = newValue
        }
    }
    
    public var imageStickerContainerView: (UIView & ZLImageStickerContainerDelegate)?
    
    private var pri_adjustTools: [ZLEditImageConfiguration.AdjustTool] = ZLEditImageConfiguration.AdjustTool.allCases



    public var adjustTools: [ZLEditImageConfiguration.AdjustTool] {
        get {
            if pri_adjustTools.isEmpty {
                return ZLEditImageConfiguration.AdjustTool.allCases
            } else {
                return pri_adjustTools
            }
        }
        set {
            pri_adjustTools = newValue
        }
    }


    public var adjustTools_objc: [Int] = [] {
        didSet {
            adjustTools = adjustTools_objc.compactMap { ZLEditImageConfiguration.AdjustTool(rawValue: $0) }
        }
    }

    public var impactFeedbackWhenAdjustSliderValueIsZero = true

    public var impactFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium

    public var dimClippedAreaDuringAdjustments = false

    public var minimumZoomScale = 1.0
}

public extension ZLEditImageConfiguration {
    @objc enum EditTool: Int, CaseIterable {
        case draw
        case clip
        case imageSticker
        case textSticker
        case mosaic
        case filter
        case adjust
    }
    
    @objc enum AdjustTool: Int, CaseIterable {
        case brightness
        case contrast
        case saturation
        
        var key: String {
            switch self {
            case .brightness:
                return kCIInputBrightnessKey
            case .contrast:
                return kCIInputContrastKey
            case .saturation:
                return kCIInputSaturationKey
            }
        }
        
        func filterValue(_ value: Float) -> Float {
            switch self {
            case .brightness:

                return value / 3
            case .contrast:

                let v: Float
                if value < 0 {
                    v = 1 + value * (1 / 2)
                } else {
                    v = 1 + value * (3 / 2)
                }
                return v
            case .saturation:

                return value + 1
            }
        }
    }
}


public extension ZLEditImageConfiguration {
    @discardableResult
    func tools(_ tools: [ZLEditImageConfiguration.EditTool]) -> ZLEditImageConfiguration {
        self.tools = tools
        return self
    }
    
    @discardableResult
    func drawColors(_ colors: [UIColor]) -> ZLEditImageConfiguration {
        drawColors = colors
        return self
    }
    
    func defaultDrawColor(_ color: UIColor) -> ZLEditImageConfiguration {
        defaultDrawColor = color
        return self
    }
    
    @discardableResult
    func clipRatios(_ ratios: [ZLImageClipRatio]) -> ZLEditImageConfiguration {
        clipRatios = ratios
        return self
    }
    
    @discardableResult
    func textStickerTextColors(_ colors: [UIColor]) -> ZLEditImageConfiguration {
        textStickerTextColors = colors
        return self
    }
    
    @discardableResult
    func textStickerDefaultTextColor(_ color: UIColor) -> ZLEditImageConfiguration {
        textStickerDefaultTextColor = color
        return self
    }
    
    @discardableResult
    func textStickerDefaultFont(_ font: UIFont?) -> ZLEditImageConfiguration {
        textStickerDefaultFont = font
        return self
    }
    
    @discardableResult
    func filters(_ filters: [ZLFilter]) -> ZLEditImageConfiguration {
        self.filters = filters
        return self
    }
    
    @discardableResult
    func imageStickerContainerView(_ view: (UIView & ZLImageStickerContainerDelegate)?) -> ZLEditImageConfiguration {
        imageStickerContainerView = view
        return self
    }
    
    @discardableResult
    func adjustTools(_ tools: [ZLEditImageConfiguration.AdjustTool]) -> ZLEditImageConfiguration {
        adjustTools = tools
        return self
    }
    
    @discardableResult
    func impactFeedbackWhenAdjustSliderValueIsZero(_ value: Bool) -> ZLEditImageConfiguration {
        impactFeedbackWhenAdjustSliderValueIsZero = value
        return self
    }
    
    @discardableResult
    func impactFeedbackStyle(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> ZLEditImageConfiguration {
        impactFeedbackStyle = style
        return self
    }
    
    @discardableResult
    func dimClippedAreaDuringAdjustments(_ value: Bool) -> ZLEditImageConfiguration {
        dimClippedAreaDuringAdjustments = value
        return self
    }
    
    @discardableResult
    func minimumZoomScale(_ value: CGFloat) -> ZLEditImageConfiguration {
        minimumZoomScale = value
        return self
    }
}


public class ZLImageClipRatio: NSObject {
    @objc public var title: String
    
    @objc public let whRatio: CGFloat
    
    @objc public let isCircle: Bool
    
    @objc public init(title: String, whRatio: CGFloat, isCircle: Bool = false) {
        self.title = title
        self.whRatio = isCircle ? 1 : whRatio
        self.isCircle = isCircle
        super.init()
    }
}

extension ZLImageClipRatio {
    static func == (lhs: ZLImageClipRatio, rhs: ZLImageClipRatio) -> Bool {
        return lhs.whRatio == rhs.whRatio && lhs.title == rhs.title
    }
}

public extension ZLImageClipRatio {
    @objc static let custom = ZLImageClipRatio(title: "custom", whRatio: 0)
    
    @objc static let circle = ZLImageClipRatio(title: "circle", whRatio: 1, isCircle: true)
    
    @objc static let wh1x1 = ZLImageClipRatio(title: "1 : 1", whRatio: 1)
    
    @objc static let wh3x4 = ZLImageClipRatio(title: "3 : 4", whRatio: 3.0 / 4.0)
    
    @objc static let wh4x3 = ZLImageClipRatio(title: "4 : 3", whRatio: 4.0 / 3.0)
    
    @objc static let wh2x3 = ZLImageClipRatio(title: "2 : 3", whRatio: 2.0 / 3.0)
    
    @objc static let wh3x2 = ZLImageClipRatio(title: "3 : 2", whRatio: 3.0 / 2.0)
    
    @objc static let wh9x16 = ZLImageClipRatio(title: "9 : 16", whRatio: 9.0 / 16.0)
    
    @objc static let wh16x9 = ZLImageClipRatio(title: "16 : 9", whRatio: 16.0 / 9.0)
}
