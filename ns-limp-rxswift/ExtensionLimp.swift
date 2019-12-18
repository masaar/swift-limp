//
//  ExtensionLimp.swift
//  ns-limp-rxswift
//
//  Created by Usman Mughal on 17/12/2019.
//  Copyright © 2019 Usman Mughal. All rights reserved.
//

import Foundation

extension Limp {
    func jsonToData(json: AnyObject) -> Data? {
        return try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    }
    func convertStringToJson(text:String, completion: @escaping ([String:Any]?)->()){
        let data = text.data(using: .utf8)!
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any> {
                completion(json)
            } else {
                completion(nil)
            }
        } catch _ as NSError {
            completion(nil)
        }
    }
}
extension Limp {
    func cacheValue(key:String, value:String?){
        UserDefaults.standard.set(value, forKey: key)
    }
    func getCachedValue(key:String) -> String? {
        let value = UserDefaults.standard.value(forKey: key) ?? nil
        return value as? String
    }
    func removeCacheValue(key:String){
        UserDefaults.standard.removeObject(forKey: key)
    }
}

extension Limp {
    open func createTravelFile(_ path: String) -> [String: Any]? {
        do {
            return try LimpFile(filePath: path).getDocObject()
        } catch {
            print("createTravelFile: ", error.localizedDescription)
            return nil
        }
    }
}
