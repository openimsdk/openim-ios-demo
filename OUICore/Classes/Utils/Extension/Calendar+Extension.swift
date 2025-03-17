
import Foundation

extension Calendar {
    public func isDateInMonth(_ date: Date) -> Bool {
        let current = Date()
        return isDate(current, equalTo: date, toGranularity: Component.month)
    }

    public func isDateInWeek(_ date: Date) -> Bool {
        return isDate(Date(), equalTo: date, toGranularity: Component.weekday)
    }
}
