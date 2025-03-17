
import Foundation

extension Array {
    public func uniqued<H: Hashable>(_ filter: (Element) -> H) -> [Element] {
        var result = [Element]()
        var map = [H: Element]()
        for ele in self {
            let key = filter(ele)
            if map[key] == nil {
                map[key] = ele
                result.append(ele)
            }
        }
        return result
    }
}
