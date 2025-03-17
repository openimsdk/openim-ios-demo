
import SnapKit
import UIKit

let minSize: CGFloat = 84

class SuspendWindow: UIWindow {
    fileprivate let coverImageName: String
    fileprivate let space: CGFloat = 8
    private var containsRootViewController: UIViewController?
    private var tipsText: String?
    
    init(rootViewController: UIViewController, coverImageName: String, tips: String?, frame: CGRect) {
        self.coverImageName = coverImageName
        super.init(frame: frame)
        self.containsRootViewController = rootViewController
        self.tipsText = tips
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        self.backgroundColor = UIColor.clear
        self.windowLevel = UIWindow.Level.alert - 1 // UIWindowLevelAlert - 1
        self.screen = UIScreen.main
        self.isHidden = false
        
        let bgView = UIView()
        bgView.isUserInteractionEnabled = true
        bgView.frame = self.bounds
        bgView.layer.masksToBounds = true
        self.addSubview(bgView)
        
        let bgImageView = UIImageView.init(image: .init(nameInBundle: "float_mini_time_bg"))
        bgView.addSubview(bgImageView)
        
        bgView.addSubview(self.iconImageView)
        bgView.addSubview(self.tipsLabel)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc fileprivate func didTap(_ tapGesture: UITapGestureRecognizer) {
        SuspendTool.sharedInstance.origin = self.frame.origin
        SuspendTool.remove(suspendWindow: self)
        self.containsRootViewController?.spread(from: self.frame.origin)
    }
    
    @objc fileprivate func didPan(_ panGesture: UIPanGestureRecognizer) {
        let point = panGesture.translation(in: panGesture.view)
        var originX = self.frame.origin.x + point.x
        if originX < self.space {
            originX = self.space
        } else if originX > UIScreen.main.bounds.width - minSize - self.space {
            originX = UIScreen.main.bounds.width - minSize - self.space
        }
        var originY = self.frame.origin.y + point.y
        if originY < self.space {
            originY = self.space
        } else if originY > UIScreen.main.bounds.height - minSize - self.space {
            originY = UIScreen.main.bounds.height - minSize - self.space
        }
        self.frame = CGRect(x: originX, y: originY, width: self.bounds.width, height: self.bounds.height)
        if panGesture.state == UIGestureRecognizer.State.cancelled || panGesture.state == UIGestureRecognizer.State.ended || panGesture.state == UIGestureRecognizer.State.failed {
            self.adjustFrameAfterPan()
            UIApplication.shared.windows.first?.makeKeyAndVisible()
        }
        panGesture.setTranslation(CGPoint.zero, in: self)
    }
    
    fileprivate func adjustFrameAfterPan() {
        var originX: CGFloat = self.space
        if self.center.x < UIScreen.main.bounds.width / 2 {
            originX = self.space
        } else if self.center.x >= UIScreen.main.bounds.width / 2 {
            originX = UIScreen.main.bounds.width - minSize - self.space
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.frame = CGRect(x: originX, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }) { _ in
            SuspendTool.setLatestOrigin(origin: self.frame.origin)
        }
    }

    lazy var tipsLabel: UILabel = {
        let tipsLabel = UILabel()
        tipsLabel.frame = CGRect(x: 0, y: iconImageView.frame.maxY + 4, width: minSize, height: 20)
        tipsLabel.center.x = self.bounds.size.width / 2
        tipsLabel.textAlignment = .center
        tipsLabel.textColor = .systemBlue
        tipsLabel.font = .systemFont(ofSize: 12)
        tipsLabel.text = tipsText ?? "等待中".localized()
        return tipsLabel
    }()
    
    lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView(image: UIImage(nameInBundle: "common_mini_phone"))
        iconImageView.isUserInteractionEnabled = true
        iconImageView.frame = CGRect(x: 0, y: 22, width: 17, height: 17)
        iconImageView.center.x = self.bounds.size.width / 2
        return iconImageView
    }()
}
