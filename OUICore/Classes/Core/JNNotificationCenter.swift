
import Foundation
import RxSwift

public final class JNNotificationCenter {
    public static let shared: JNNotificationCenter = .init()

    private static let EventKey = "event"

    public func observeEvent<T: Event>(using: @escaping (T) -> Void) -> Disposable {
        let name: NSNotification.Name = getNotificationNameOf(event: T.self)
        let ob = _nc.addObserver(forName: name, object: nil, queue: nil) { (nt: Notification) in
            using(nt.userInfo![JNNotificationCenter.EventKey] as! T)
        }
        return Disposables.create { [weak self] in
            self?._nc.removeObserver(ob)
        }
    }

    public func post<T: Event>(_ event: T) {
        guard Thread.current.isMainThread else {
            fatalError("post方法必须在主线程调用")
        }
        let name: NSNotification.Name = getNotificationNameOf(event: type(of: event).self)
        _nc.post(name: name, object: nil, userInfo: [JNNotificationCenter.EventKey: event])
    }

    private func getNotificationNameOf(event: AnyClass) -> NSNotification.Name {
        let eventName = event.description()
        return NSNotification.Name(eventName)
    }

    private let _nc: NotificationCenter = .init()
}

open class Event {
    init() {}
}
