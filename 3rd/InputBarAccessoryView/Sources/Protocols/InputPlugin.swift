


























import UIKit

public protocol InputPlugin: AnyObject {

    func reloadData()

    func invalidate()



    func handleInput(of object: AnyObject) -> Bool
}
