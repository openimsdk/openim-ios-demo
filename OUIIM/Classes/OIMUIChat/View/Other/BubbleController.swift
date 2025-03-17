import ChatLayout
import Foundation
import UIKit
import OUICore

protocol BubbleController {}

final class TextBubbleController<CustomView: UIView>: BubbleController {

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: UIView? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: UIView, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }
        UIView.performWithoutAnimation {
            let marginOffset: CGFloat = type.isIncoming ? -StandardUI.tailSize : StandardUI.tailSize
            let edgeInsets = UIEdgeInsets(top: 8, left: 12 - marginOffset, bottom: 8, right: 12 + marginOffset)
            bubbleView.layoutMargins = edgeInsets

            if #available(iOS 13.0, *) {
                bubbleView.backgroundColor = type.isIncoming ? .cF4F5F7 : .cCCE7FE
            } else {
                let systemGray5 = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
                bubbleView.backgroundColor = type.isIncoming ? systemGray5 : .systemBlue
            }
        }
    }
}

final class FileBubbleController<CustomView: UIView>: BubbleController {

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: UIView? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: UIView, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }
        
        UIView.performWithoutAnimation {

            let marginOffset: CGFloat = type.isIncoming ? -StandardUI.tailSize : StandardUI.tailSize
            let edgeInsets = UIEdgeInsets(top: 8, left: 8 - marginOffset, bottom: 8, right: 8 + marginOffset)
            bubbleView.layoutMargins = edgeInsets
            
            if #available(iOS 13.0, *) {
                bubbleView.backgroundColor = type.isIncoming ? .cF4F5F7 : .cCCE7FE
            } else {
                let systemGray5 = UIColor(red: 200 / 255, green: 200 / 255, blue: 200 / 255, alpha: 1)
                bubbleView.backgroundColor = type.isIncoming ? systemGray5 : .systemBlue
            }
        }
    }
}

final class FullCellContentBubbleController<CustomView: UIView>: BubbleController {

    weak var bubbleView: BezierMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: BezierMaskedView<CustomView>) {
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }

        UIView.performWithoutAnimation {
            bubbleView.backgroundColor = .clear
            bubbleView.customView.layoutMargins = .zero
        }
    }
}

final class ReplyBubbleController<CustomView: UIView>: BubbleController {

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: UIView? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: UIView, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }
        UIView.performWithoutAnimation {
            let marginOffset: CGFloat = type.isIncoming ? -StandardUI.tailSize : StandardUI.tailSize
            let edgeInsets = UIEdgeInsets(top: 0, left: 2 - marginOffset, bottom: 0, right: 2 + marginOffset)
            bubbleView.layoutMargins = edgeInsets
            
            bubbleView.backgroundColor = .clear
        }
    }
}

final class BlankBubbleController<CustomView: UIView>: BubbleController {

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: UIView? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: UIView, type: MessageType, bubbleType: Cell.BubbleType) {
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }
        UIView.performWithoutAnimation {
            let edgeInsets = type.isIncoming ? UIEdgeInsets(top: 0, left: 2 + StandardUI.tailSize, bottom: 0, right:  2) : UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2 + StandardUI.tailSize)
            bubbleView.layoutMargins = edgeInsets
            
            bubbleView.backgroundColor = .clear
        }
    }
}

final class BezierBubbleController<CustomView: UIView>: BubbleController {

    private let controllerProxy: BubbleController

    private let type: MessageType

    private let bubbleType: Cell.BubbleType

    weak var bubbleView: BezierMaskedView<CustomView>? {
        didSet {
            setupBubbleView()
        }
    }

    init(bubbleView: BezierMaskedView<CustomView>, controllerProxy: BubbleController, type: MessageType, bubbleType: Cell.BubbleType) {
        self.controllerProxy = controllerProxy
        self.type = type
        self.bubbleType = bubbleType
        self.bubbleView = bubbleView
        setupBubbleView()
    }

    private func setupBubbleView() {
        guard let bubbleView else {
            return
        }

        bubbleView.messageType = type
        bubbleView.bubbleType = bubbleType
    }
}
