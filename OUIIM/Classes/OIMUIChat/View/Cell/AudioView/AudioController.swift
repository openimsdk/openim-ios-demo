import Foundation
import AVFAudio
import OUICore

class AudioController: CellBaseController {
        
    weak var view: AudioView? {
        didSet {
            view?.reloadData()
        }
    }

    var state: AudioViewState = .loading
    
    var duration: Int = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var canPlay: Bool = false
    private var source: MediaMessageSource!
    
    init(source: MediaMessageSource, messageID: String, messageType: MessageType = .incoming, bubbleController: BubbleController) {
        super.init(messageID: messageID, messageType: messageType, bubbleController: bubbleController)
        
        self.source = source
        self.duration = source.duration ?? 0
    }
    
    deinit {
        AudioPlayController.shared.reset() 
    }
    
    func action() {
        let canNext = onTap?(.audio(source, isLocallyStored: true))
        
        guard let url = source.source.url, canNext == true else { return }
        
        let audioPlayController = AudioPlayController.shared

        if audioPlayController.isPausing(messageID: messageID) || audioPlayController.isPlaying(messageID: messageID) {

            if audioPlayController.isPausing(messageID: messageID) {
                audioPlayController.play(url: url, messageID: messageID)
                state = .play
                view?.reloadData()
            } else if audioPlayController.isPlaying(messageID: messageID) {

                audioPlayController.pause(messageID: messageID)
                state = .idle
                view?.reloadData()
            }
            
            return
        }

        audioPlayController.stop()

        audioPlayController.focus(messageID: messageID)
        
        if url.isFileURL {
            audioPlayController.play(url: url, messageID: messageID)
            state = .play
            view?.reloadData()
        } else {
            let localURL = FileHelper.shared.exsit(path: url.absoluteString)

            if localURL == nil {
                FileDownloadManager.manager.downloadMessageFile(messageID: messageID, url: url) { [weak self] msgID, location in
                    guard let self else { return }
                    
                    var temp = FileHelper.shared.exsit(path: location.path, name: location.lastPathComponent)
                    
                    if temp == nil {
                        temp = FileHelper.shared.saveAudio(from: location.path, name: location.lastPathComponent).fullPath
                    }
                    
                    guard let temp else { return }
                    
                    let r = URL(fileURLWithPath: temp)

                    if AudioPlayController.shared.isFocus(messageID: msgID) {
                        DispatchQueue.main.async {
                            AudioPlayController.shared.play(url: r, messageID: msgID)
                            self.state = .play
                            self.view?.reloadData()
                        }
                    }
                }
            } else {
                let url = URL(fileURLWithPath: localURL!)
                audioPlayController.play(url: url, messageID: messageID)
                state = .play
                view?.reloadData()
            }
        }
        
        audioPlayController.didFinishPlaying = { [weak self] msgID in
            guard self?.messageID == msgID else { return }
            self?.state = .idle
            self?.view?.reloadData()
        }
    }
}
