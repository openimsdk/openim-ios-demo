
import RxSwift
import OUICore

class FilePreviewViewController: UIViewController {
    
    private let _disposeBag = DisposeBag()
    private var documentInteractionController: UIDocumentInteractionController!
    
    private var _messageID: String = ""
    private var _name: String = ""
    private var _size: Int = 0
    private var _url: String = ""
    
    private var downloadRequest: FileDownloadRequest?
    
    init(messageID: String, name: String, size: Int, url: String) {
        super.init(nibName: nil, bundle: nil)
        _messageID = messageID
        _name = name
        _size = size
        _url = url
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var nameLabel: UILabel = {
        let t = UILabel()
        t.textAlignment = .center
        t.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        return t
    }()
    
    
    lazy var sizeLabel: UILabel = {
        let t = UILabel()
        t.textAlignment = .center
        
        t.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        return t
    }()
    
    
    lazy var downloadButton: UIButton = {
        let t = UIButton()
        t.setImage(.init(nameInBundle: "ic_download_continue"), for: .normal)
        t.setImage(.init(nameInBundle: "ic_download_stop"), for: .selected)
        
        t.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let sself = self else { return }
            t.isSelected = !t.isSelected
            sself.toggleDownload(t.isSelected)
        }).disposed(by: _disposeBag)
        return t
    }()
    
    lazy var progressView: CircularProgressView = {
        let t = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 50, height: 50), lineWidth: 5, rounded: false)
        t.addSubview(downloadButton)
        
        t.snp.makeConstraints { make in
            make.size.equalTo(50)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.size.equalTo(38)
            make.center.equalToSuperview()
        }
        return t
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .viewBackgroundColor
        setupView()
        startDownload()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }
    
    func setupView() {
        nameLabel.text = _name
        sizeLabel.text = "文档大小:".innerLocalized() + FileHelper.formatLength(length: _size)
        
        let baseInfoStackView = UIStackView.init(arrangedSubviews: [SizeBox(height: 40), nameLabel, sizeLabel])
        baseInfoStackView.axis = .vertical
        baseInfoStackView.spacing = 8
        
        let verStackView = UIStackView.init(arrangedSubviews: [baseInfoStackView, UIView(), progressView, UIView()])
        verStackView.axis = .vertical
        verStackView.spacing = 8
        verStackView.alignment = .center
        verStackView.distribution = .equalSpacing
        view.addSubview(verStackView)
        
        verStackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    func startDownload() {
        if let localURL = FileHelper.shared.exsit(path: _url, name: _name) {
            downloadButtonCompletionStatus(URL(fileURLWithPath: localURL))
            return
        }
        
        guard let url = URL(string: _url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
        downloadRequest = FileDownloadManager.manager.downloadMessageFile(messageID: _messageID,
                                                                          url: url,
                                                                          name: _name) { [weak self] (messageID, written, total) in
            guard let self, self._messageID == messageID else { return }
            DispatchQueue.main.async { [self] in
                self.progressView.progress = CGFloat(written) / CGFloat(total)
            }
        } completion: { [weak self] (messageID, url) in
            let result = FileHelper.shared.saveFile(from: url.path, name: self?._name)
            
            DispatchQueue.main.async { [self] in
                self?.downloadButtonCompletionStatus(URL(fileURLWithPath: result.fullPath))
            }
        }
    }
    
    func downloadButtonCompletionStatus(_ url: URL) {
        
        downloadButton.setTitle("打开".innerLocalized(), for: .normal)
        downloadButton.setTitleColor(.systemBlue, for: .normal)
        downloadButton.setImage(nil, for: .normal)
        downloadButton.setImage(nil, for: .selected)
        progressView.progressColor = .clear
        progressView.trackColor = .clear
        
        downloadButton.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self else { return }
            showFile(url: url)
        }).disposed(by: _disposeBag)
    }
    
    func toggleDownload(_ suspend: Bool = false) {
        if suspend {
            downloadRequest?.request.suspend()
        } else {
            downloadRequest?.request.resume()
        }
    }
    
    func showFile(url: URL) {
        documentInteractionController = UIDocumentInteractionController(url: url)
        documentInteractionController.delegate = self

        let r = documentInteractionController.presentPreview(animated: true)
        if !r {
            documentInteractionController.presentOptionsMenu(from: view.bounds, in: view, animated: true)
        }
    }
}

extension FilePreviewViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.frame
    }
    
    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        print("Dismissed!!!")
    }
}

class CircularProgressView: UIView {
    
    fileprivate var progressLayer = CAShapeLayer()
    fileprivate var trackLayer = CAShapeLayer()
    fileprivate var didConfigureLabel = false
    fileprivate var rounded: Bool
    fileprivate var filled: Bool
    
    fileprivate let lineWidth: CGFloat?
    var timeToFill = 1.43
    
    var progressColor = UIColor.systemBlue {
        didSet{
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor = UIColor.systemGray6 {
        didSet{
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var progress: CGFloat {
        didSet{
            var pathMoved = progress - oldValue
            if pathMoved < 0{
                pathMoved = 0 - pathMoved
            }
            
            setProgress(duration: timeToFill * Double(pathMoved), to: progress)
        }
    }
    
    fileprivate func createProgressView(){
        
        self.backgroundColor = .clear
        self.layer.cornerRadius = frame.size.width / 2
        let circularPath = UIBezierPath(arcCenter: center, radius: frame.width / 2, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        trackLayer.fillColor = UIColor.blue.cgColor
        
        trackLayer.path = circularPath.cgPath
        trackLayer.fillColor = .none
        trackLayer.strokeColor = trackColor.cgColor
        
        if filled {
            trackLayer.lineCap = .butt
            trackLayer.lineWidth = frame.width
        }else{
            trackLayer.lineWidth = lineWidth!
        }
        trackLayer.strokeEnd = 1
        layer.addSublayer(trackLayer)
        
        progressLayer.path = circularPath.cgPath
        progressLayer.fillColor = .none
        progressLayer.strokeColor = progressColor.cgColor
        if filled {
            progressLayer.lineCap = .butt
            progressLayer.lineWidth = frame.width
        }else{
            progressLayer.lineWidth = lineWidth!
        }
        progressLayer.strokeEnd = 0
        if rounded{
            progressLayer.lineCap = .round
        }
        
        layer.addSublayer(progressLayer)
    }
    
    func trackColorToProgressColor() -> Void{
        trackColor = progressColor
        trackColor = UIColor(red: progressColor.cgColor.components![0], green: progressColor.cgColor.components![1], blue: progressColor.cgColor.components![2], alpha: 0.2)
    }
    
    func setProgress(duration: TimeInterval = 3, to newProgress: CGFloat) -> Void{
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = newProgress
        
        progressLayer.strokeEnd = CGFloat(newProgress)
        progressLayer.add(animation, forKey: "animationProgress")
    }
    
    override init(frame: CGRect){
        progress = 0
        rounded = true
        filled = false
        lineWidth = 15
        super.init(frame: frame)
        filled = false
        createProgressView()
    }
    
    required init?(coder: NSCoder) {
        progress = 0
        rounded = true
        filled = false
        lineWidth = 15
        super.init(coder: coder)
        createProgressView()
    }
    
    init(frame: CGRect, lineWidth: CGFloat?, rounded: Bool) {
        progress = 0
        
        if lineWidth == nil{
            self.filled = true
            self.rounded = false
        }else{
            if rounded{
                self.rounded = true
            }else{
                self.rounded = false
            }
            self.filled = false
        }
        self.lineWidth = lineWidth
        
        super.init(frame: frame)
        createProgressView()
    }
}
