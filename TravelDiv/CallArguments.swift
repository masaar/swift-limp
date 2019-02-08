

import Foundation

public class CallArguments:Codable{
    
    let call_id:String?
    let endpoint:String
    let sid:String?
    let token:String?
    let query:AnyCodable?
    let doc:AnyCodable?
    
    public init(call_id:String? = nil, endpoint:String, authed:Bool, query:Any? = nil, doc: Any? = nil) {
        
        let random = String(Int.random(in: 0..<36))
        let randomCallId = String(random.prefix(7))
        
        let cacheSid:String = UserDefaults.standard.value(forKey: "sid") as? String ?? "f00000000000000000000012"
        let cacheToken:String = UserDefaults.standard.value(forKey: "token") as? String ?? TravelEnvironment.nonToken
        
        self.call_id = call_id ?? randomCallId
        self.endpoint = endpoint
        self.sid = authed ? cacheSid  : "f00000000000000000000012"
        self.token = authed ? cacheToken : TravelEnvironment.nonToken
        self.query = AnyCodable(value: query ?? [:] as Any)
        self.doc =  AnyCodable(value: doc ?? [:] as Any)
        
    }
    func encode() throws -> String  {
        let data = try JSONEncoder().encode(self)
        return data.base64urlEncodedString()
    }
}
