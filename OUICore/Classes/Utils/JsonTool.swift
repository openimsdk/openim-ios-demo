
import Foundation

public struct JsonTool {
    public static func fromJson<T: Decodable>(_ json: String, toClass: T.Type) -> T? {
        let decoder = JSONDecoder()
        do {
            let result = try decoder.decode(toClass, from: json.data(using: .utf8)!)
            return result
        } catch DecodingError.dataCorrupted(let c) {
            print("dataCorrupted")
            return nil
        } catch DecodingError.keyNotFound(let c, let d) {
            print("keyNotFound")
            return nil
        } catch DecodingError.typeMismatch(let c, let d) {
            print("typeMismatch")
            return nil
        } catch DecodingError.valueNotFound(let c, let d) {
            print("valueNotFound")
            return nil
        } catch _ {
            return nil
        }
    }
    
    public static func fromMap<T: Decodable>(_ map: [String: Any], toClass: T.Type) -> T? {
        do {
            let json = try JSONSerialization.data(withJSONObject: map, options: .fragmentsAllowed)
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(toClass, from: json)
                return result
            } catch DecodingError.dataCorrupted(let c) {
                print("dataCorrupted")
                return nil
            } catch DecodingError.keyNotFound(let c, let d) {
                print("keyNotFound")
                return nil
            } catch DecodingError.typeMismatch(let c, let d) {
                print("typeMismatch")
                return nil
            } catch DecodingError.valueNotFound(let c, let d) {
                print("valueNotFound")
                return nil
            } catch _ {
                return nil
            }
        } catch (let e) {
            print("fromMap Exception:\(e)")
            return nil
        }
    }
    
    public static func toJson<T: Encodable>(fromObject: T) -> String {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard var json = String(data: data, encoding: .utf8) else {
                fatalError("check your data is encodable from utf8!")
            }
            json = json.replacingOccurrences(of: "\\", with: "")
            
            return json
        } catch let err {
            return ""
        }
    }
    
    public static func toMap<T: Encodable>(fromObject: T) -> [String: Any] {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(fromObject)
            guard let map = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                fatalError("check your data is encodable from utf8!")
            }
            
            print("JsonTool \(#function)：\(map)")
            return map
        } catch _ {
            return [:]
        }
    }
}
