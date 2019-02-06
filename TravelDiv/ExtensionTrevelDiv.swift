//
//  ExtensionTrevelDiv.swift
//  TravelDiv
//
//  Created by Usman Mughal on 02/02/2019.
//

import Foundation

public class CallArguments:Codable{
   
    let call_id:String?
    let endpoint:String
    let sid:String?
    let token:String?
    let query:[String: [String:String]]?
    let doc:[String: String]?
    
    let name:String?
    let desc:String?
    let coords:[String: [String:String]]?
    let zoom:String?
    
    public init(call_id:String? = nil, endpoint:String, authed:Bool, query:[String: [String:String]]? = nil, doc:[String: String]? = nil, name:String? = nil, desc:String? = nil, coords:[String: [String:String]]? = nil, zoom:String? = nil) {
        
        let random = String(Int.random(in: 0..<36))
        let randomCallId = String(random.prefix(7))
        
        let cacheSid:String = UserDefaults.standard.value(forKey: "sid") as? String ?? "f00000000000000000000012"
        let cacheToken:String = UserDefaults.standard.value(forKey: "token") as? String ?? "__ANON"
        
        self.call_id = call_id ?? randomCallId
        self.endpoint = endpoint
        self.sid = authed ? cacheSid  : "f00000000000000000000012"
        self.token = authed ? cacheToken : "__ANON"
        self.query = query ?? [String:[String:String]]()
        self.doc = doc
        
        self.name = name
        self.desc = desc
        self.coords = coords
        self.zoom = zoom
    }
    func encode() throws -> String  {
        let data = try JSONEncoder().encode(self)
        return data.base64urlEncodedString()
    }
}

extension TravelDiv {
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

extension TravelDiv {
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
