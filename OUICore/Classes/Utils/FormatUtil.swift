
import Foundation

public struct FormatUtil {
    public static func getMediaFormat(of seconds: Int) -> String {
        if seconds / 3600 > 24 {
            return "时长超过了24小时，请检查输入值"
        }
        if seconds / 3600 > 0 {
            let hour = seconds / 3600
            let min = seconds % 3600 / 60
            let sec = seconds % 3600 % 60
            return String(format: "%02d:%02d:%02d", hour, min, sec)
        } else {
            let min = seconds / 60
            let sec = seconds % 60 % 60
            return String(format: "%02d:%02d", min, sec)
        }
    }
    
    public static func getMutedFormat(of mutedSeconds: Int) -> String {
        var dispalySeconds = ""
        
        if (mutedSeconds < 3600) {
            dispalySeconds = "\(mutedSeconds / 60)" + "分钟".innerLocalized()
        } else if mutedSeconds < 24 * 3600 {
            dispalySeconds = "\(mutedSeconds / 3600)" + "小时".innerLocalized()
        } else {
            dispalySeconds = "\(mutedSeconds / (24 * 3600))" + "天".innerLocalized()
        }
        
        return dispalySeconds
    }

    public static func getFormatDate(formatString: String = "yyyy/MM/dd", of seconds: Int) -> String {
        let format = DateFormatter()
        format.dateFormat = formatString
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let str = format.string(from: date)
        return str
    }

    public static func getFileSizeDesc(fileSize: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let ret = formatter.string(fromByteCount: Int64(fileSize))
        return ret
    }

    static func isWeek(seconds: Int) -> Bool {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let ret = Calendar.current.isDateInWeekend(date)
        return ret
    }

    static func isThisMonth(seconds: Int) -> Bool {
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let ret = Calendar.current.isDateInMonth(date)
        return ret
    }
}

extension Date {
    
    public static func formatDate(_ formatString: String = "yyyy/MM/dd", of seconds: Int) -> String {
        let format = DateFormatter()
        format.dateFormat = formatString
        let date = Date(timeIntervalSince1970: TimeInterval(seconds))
        let str = format.string(from: date)
        return str
    }
    
    public static func timeString(date: Date) -> String {
        let timeInterval = date.timeIntervalSince1970 * 1000
        return timeString(timeInterval: timeInterval)
    }



    public static func timeString(timeInterval: TimeInterval) -> String {
        
        var interval = timeInterval

        if String(Int(timeInterval)).count > 10 {
            interval = ceil(timeInterval / 1000)
        }
        
        let date = getNowDateFromatAnDate(Date(timeIntervalSince1970: interval))
        
        let formatter = DateFormatter()
        if date.isToday() {
            formatter.dateFormat = "HH:mm"
            
            return formatter.string(from: date)
        } else if date.isYesterday() {
            formatter.dateFormat = "HH:mm"
            let dataTime = "\("昨天".innerLocalized()) \(formatter.string(from: date))"
            
            return dataTime
        } else if date.isSameWeek() {
            let week = date.weekdayStringFromDate()
            formatter.dateFormat = "HH:mm"
            let dataTime = "\(week) \(formatter.string(from: date))"
            
            return dataTime
        } else {
            formatter.dateFormat = "MM-dd HH:mm"
            
            return formatter.string(from: date)
        }
    }
    
    public func isToday() -> Bool {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.day,.month,.year], from: Date() )
        let selfComponents = calendar.dateComponents([.day,.month,.year], from: self as Date)
        
        return (selfComponents.year == nowComponents.year) && (selfComponents.month == nowComponents.month) && (selfComponents.day == nowComponents.day)
    }
    
    func isYesterday() -> Bool {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.day], from: Date() )
        let selfComponents = calendar.dateComponents([.day], from: self as Date)
        let cmps = calendar.dateComponents([.day], from: selfComponents, to: nowComponents)
        return cmps.day == 1
        
    }
    
    func isSameWeek() -> Bool {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        let selfComponents = calendar.dateComponents([.day, .month, .year], from: self as Date)
        
        return (selfComponents.year == nowComponents.year) && (selfComponents.month == nowComponents.month) && (selfComponents.weekday == nowComponents.weekday)
    }
    
    func weekdayStringFromDate() -> String {
        let weekdays: NSArray = ["星期日".innerLocalized(), "星期一".innerLocalized(), "星期二".innerLocalized(), "星期三".innerLocalized(), "星期四".innerLocalized(), "星期五".innerLocalized(), "星期六".innerLocalized()]
        var calendar = Calendar.init(identifier: .gregorian)
        let timeZone = TimeZone.current
        calendar.timeZone = timeZone
        let theComponents = calendar.dateComponents([.weekday], from: self as Date)
        return weekdays.object(at: theComponents.weekday! - 1) as! String
    }

    static func getNowDateFromatAnDate(_ anyDate: Date?) -> Date {

        let sourceTimeZone = NSTimeZone.local as NSTimeZone


        let destinationTimeZone = NSTimeZone.local as NSTimeZone

        var sourceGMTOffset: Int? = nil
        if let aDate = anyDate {
            sourceGMTOffset = sourceTimeZone.secondsFromGMT(for: aDate)
        }

        var destinationGMTOffset: Int? = nil
        if let aDate = anyDate {
            destinationGMTOffset = destinationTimeZone.secondsFromGMT(for: aDate)
        }

        let interval = TimeInterval((destinationGMTOffset ?? 0) - (sourceGMTOffset ?? 0))

        var destinationDateNow: Date? = nil
        if let aDate = anyDate {
            destinationDateNow = Date(timeInterval: interval, since: aDate)
        }
        return destinationDateNow!
    }
    
    static public func formatTime(seconds: Int) -> String {

        let minutesInHour = 60
        let secondsInMinute = 60
        let secondsInHour = minutesInHour * secondsInMinute

        if seconds == 0 {
            return "nSeconds".innerLocalizedFormat(arguments: "0")
        }

        let hours = seconds / secondsInHour
        let minutes = (seconds % secondsInHour) / secondsInMinute
        let remainingSeconds = seconds % secondsInMinute

        if hours > 0 {
            if minutes > 0 {
                let totalHours = Double(seconds) / Double(secondsInHour)

                if totalHours.truncatingRemainder(dividingBy: 1) == 0 {
                    return "nHour".innerLocalizedFormat(arguments: String(Int(totalHours)))
                } else {
                    return "nHour".innerLocalizedFormat(arguments: String(totalHours))
                }
            } else {
                return "nHour".innerLocalizedFormat(arguments: String(hours))
            }
        } else if minutes > 0 {
            let totalMinutes = Double(seconds) / Double(secondsInMinute)

            if totalMinutes.truncatingRemainder(dividingBy: 1) == 0 {
                return "nMinute".innerLocalizedFormat(arguments: String(Int(totalMinutes)))
            } else {
                
                return "nMinute".innerLocalizedFormat(arguments: String(totalMinutes))
            }
        } else {
            return "nSeconds".innerLocalizedFormat(arguments: String(remainingSeconds))
        }
    }
}
