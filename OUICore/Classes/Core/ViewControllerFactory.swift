
import Foundation

public enum ViewControllerFactory {
    public static func getBundle() -> Bundle? {
        guard let path = Bundle(for: IMController.self).resourcePath else { return nil }
        var finalPath: String = path
        finalPath.append("/OIMUIResource.bundle")
        let bundle = Bundle(path: finalPath)
        return bundle
    }

    public static func getEmojiBundle() -> Bundle? {
        guard let path = Bundle(for: IMController.self).resourcePath else { return nil }
        var finalPath: String = path
        finalPath.append("/OIMUIEmoji.bundle")
        let bundle = Bundle(path: finalPath)
        return bundle
    }

    public static func getContactStoryboard() -> UIStoryboard {
        let storyboard = UIStoryboard(name: "OIMContacts", bundle: getBundle())
        return storyboard
    }
}
