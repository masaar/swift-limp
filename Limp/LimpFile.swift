//
//  LimpFile.swift
//  Limp
//
//

import Foundation

class LimpFile: Codable {
    
    var name:String? = ""
    var size:UInt64? = 0
    var type:String? = ""
    var lastModified:Int64? = 0
    var content: [Int]? = [Int]()
    
    init(filePath:String) {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            let dict = attr as NSDictionary
            self.size = dict.fileSize()
            self.type = dict.fileType()
            self.lastModified = dict.fileModificationDate()?.toMillis()
            self.name = (filePath as NSString).lastPathComponent
            
            let filePath = filePath
            var bytes = [UInt8]()
            if let data = NSData(contentsOfFile: filePath) {
                var buffer = [UInt8](repeating: 0, count: data.length)
                data.getBytes(&buffer, length: data.length)
                bytes = buffer
                self.content = bytes.map { Int($0) }
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func getDocObject() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any>
    }
}
extension Date {
    func toMillis() -> Int64! {
        return Int64(self.timeIntervalSince1970 * 1000)
    }
}

