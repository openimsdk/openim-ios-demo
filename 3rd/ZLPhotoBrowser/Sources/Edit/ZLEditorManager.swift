

























import Foundation

public enum ZLEditorAction {
    case draw(ZLDrawPath)
    case eraser([ZLDrawPath])
    case clip(oldStatus: ZLClipStatus, newStatus: ZLClipStatus)
    case sticker(oldState: ZLBaseStickertState?, newState: ZLBaseStickertState?)
    case mosaic(ZLMosaicPath)
    case filter(oldFilter: ZLFilter?, newFilter: ZLFilter?)
    case adjust(oldStatus: ZLAdjustStatus, newStatus: ZLAdjustStatus)
}

protocol ZLEditorManagerDelegate: AnyObject {
    func editorManager(_ manager: ZLEditorManager, didUpdateActions actions: [ZLEditorAction], redoActions: [ZLEditorAction])
    
    func editorManager(_ manager: ZLEditorManager, undoAction action: ZLEditorAction)
    
    func editorManager(_ manager: ZLEditorManager, redoAction action: ZLEditorAction)
}

class ZLEditorManager {
    private(set) var actions: [ZLEditorAction] = []
    private(set) var redoActions: [ZLEditorAction] = []
    
    weak var delegate: ZLEditorManagerDelegate?
    
    init(actions: [ZLEditorAction] = []) {
        self.actions = actions
        redoActions = actions
    }
    
    func storeAction(_ action: ZLEditorAction) {
        actions.append(action)
        redoActions = actions
        
        deliverUpdate()
    }
    
    func undoAction() {
        guard let preAction = actions.popLast() else { return }
        
        delegate?.editorManager(self, undoAction: preAction)
        deliverUpdate()
    }
    
    func redoAction() {
        guard actions.count < redoActions.count else { return }
        
        let action = redoActions[actions.count]
        actions.append(action)
        
        delegate?.editorManager(self, redoAction: action)
        deliverUpdate()
    }
    
    private func deliverUpdate() {
        delegate?.editorManager(self, didUpdateActions: actions, redoActions: redoActions)
    }
}
