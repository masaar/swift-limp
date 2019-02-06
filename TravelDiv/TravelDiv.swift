//
//  TravelDiv.swift
//  TravelDiv
//
//  Created by Usman Mughal on 30/01/2019.
//

import UIKit

public enum CredentialType:String {
    case username
    case email
    case phone
}

public struct ResponseArguments {
    var call_id : String?
    var docs : [Any]?
    var count : Int?
    var total : Int?
    var groups : Any?
    var code : String?
}

public struct SocketResponse {
    var args: ResponseArguments?
    var msg: String?
    var status: Int?
}

public protocol TravelDivDelegate: class {
    func didDisconnect(_ result: Bool, error:Error?)
    func didReceive(_ result:Bool, response:SocketResponse)
}

open class TravelDiv: NSObject {
    
    static fileprivate let _shared = TravelDiv()
    open class func API() -> TravelDiv {
        return _shared
    }
    var authed = false
    var session: Any? = nil
    public var delegate: TravelDivDelegate?
//    delegate?.changeBackgroundColor(tapGesture.view?.backgroundColor)
    
    let header = Header(alg: "HS256", typ: "JWT")
    var socket = WebSocket(url: URL(string: "ws://api-points.masaar.com/ws")!) // Dev server
//    var socket = WebSocket(url: URL(string: "wss://api-maps.traveldiv.net/ws")!) // Prod server
    
    private func setListener(listener: @escaping (Bool, SocketResponse) -> ()) {
        socket.onDisconnect = { (error: Error?) in
            // TODO: Handle error internally
            self.delegate?.didDisconnect(false, error: error)
            listener(false, SocketResponse(args: nil, msg: nil, status: nil))
        }
        socket.onText = { (text: String) in
            self.convertStringToJson(text: text, completion: { (json) in
                if let jsonValue = json {
                    let status = jsonValue["status"] as? Int
                    let msg = jsonValue["msg"] as? String
                    
                    let arg = jsonValue["args"] as? [String:Any]
                    let call_id = arg?["call_id"] as? String
                    let docs = arg?["docs"] as? [Any]
                    let count = arg?["count"] as? Int
                    let total = arg?["total"] as? Int
                    let groups = arg?["groups"]
                    let postal_code = arg?["postal_code"] as? String
                    
                    let args = ResponseArguments(call_id:call_id, docs: docs, count: count, total: total, groups: groups, code: postal_code)
                    let response = SocketResponse(args: args, msg: msg, status: status)
                    self.delegate?.didReceive(true, response: response)
                    listener(true, response)
                    
                }else{
                    let response = SocketResponse(args: nil, msg: nil, status: nil)
                    self.delegate?.didReceive(true, response: response)
                    listener(true, response)
                }
            })
        }
        socket.onData = { (data: Data) in
            // TODO: handle data response
            // listener(true, SocketResponse(args: args, msg: msg, status: status)
        }
    }
    
    open func initilize(completion: @escaping (Bool, SocketResponse) -> ()) {
        setListener { (success, response) in
            completion(success, response)
        }
        socket.connect()
    }
    
    open func isAuthed() -> Any? {
        return session
    }
    
    func generateAuthHash(authVar: CredentialType, authVal: String, password: String) throws -> String {
        var authJWT = JWT(header: header, payload: ["hash":[authVar.rawValue, authVal, password]])
        let token = JWTSigner.hs256(key: password.data(using: .utf8)!)
        let hash = try authJWT.sign(using: token)
        let smallHash = hash.components(separatedBy: ".")[1]
        return smallHash
    }
    
    open func auth(authVar:CredentialType, authVal:String, password:String, completion: @escaping (Bool, SocketResponse) -> ()){
        do {
            let hash = try generateAuthHash(authVar: authVar, authVal: authVal, password: password)
            let json = CallArguments(endpoint: "session/auth",
                            authed: self.authed,
                            doc: [authVar.rawValue:authVal,"hash" : hash])
            
            self.authed = false
            self.removeCacheValue(key: "token")
            self.removeCacheValue(key: "sid")
            self.session = nil
            
            call(callArgs: json) { (success, response) in
                self.authed = true
                self.session = response.args?.docs?[0]
                let dic = response.args?.docs?[0] as? [String:Any]
                let token = dic?["token"] as? String
                let sid = dic?["_id"] as? String
                self.cacheValue(key: "token", value: token)
                self.cacheValue(key: "sid", value: sid)
                completion(success, response)
            }
        } catch {
            //handle error
            print(error)
            completion(false, SocketResponse(args: nil, msg: error.localizedDescription, status: nil))
        }
    }
    
    open func reauth(completion: @escaping (Bool, SocketResponse) -> ()){
        let cacheToken:String = self.getCachedValue(key: "token") ?? "__ANON"
        let cacheSid:String = self.getCachedValue(key: "sid") ?? "f00000000000000000000012"
        do{
            var authJWT = JWT(header: header, payload: ["token":cacheToken])
            let token = JWTSigner.hs256(key: cacheToken.data(using: .utf8)!)
            let hash = try authJWT.sign(using: token)
            let smallHash = hash.components(separatedBy: ".")[1]
            
            let json = CallArguments(endpoint: "session/reauth",
                                     authed: self.authed,
                                     query: ["_id" : ["val" : cacheSid], "hash" : ["val" : smallHash]])
            
            call(callArgs: json) { (success, response) in
                completion(success, response)
            }
        }catch{
            completion(false, SocketResponse(args: nil, msg: error.localizedDescription, status: nil))
        }
    }
    
    open func signout(completion: @escaping (Bool, SocketResponse) -> ()){
            let cacheSid:String = self.getCachedValue(key: "sid") ?? "f00000000000000000000012"
            let json = CallArguments(endpoint: "session/signout",
                            authed: self.authed,
                            query: ["_id" : ["val" : cacheSid]])
            call(callArgs: json) { (success, response) in
                completion(success, response)
        }
    }
    
    open func checkAuth(completion: @escaping (Bool, SocketResponse) -> ()){
        let token = self.getCachedValue(key: "token")
        let sid = self.getCachedValue(key: "sid")
        if ((token == nil) || (sid == nil)){
            completion(false, SocketResponse(args: nil, msg: "No credentials cached.", status: nil))
        }else{
            self.reauth() { (success, response) in
                if response.status == 500 || response.status == 403 {
                    completion(false, SocketResponse(args: nil, msg: "Wrong credentials cached.", status: 403))
                }else{
                    self.authed = true
                    self.session = response.args?.docs?[0]
                    completion(success, response)
                }
            }
        }
    }
    
    open func call(callArgs:CallArguments, binary:Bool = false, completion: @escaping (Bool, SocketResponse) -> ()){
        do{
            var authJWT = JWT(header: header, payload: callArgs)
            let token = JWTSigner.hs256(key: callArgs.token!.data(using: .utf8)!)
            let finalHashAuth = try authJWT.sign(using: token)
            setListener { (success, response) in
                completion(success, response)
            }
            let json: [String: Any] = [ "token": finalHashAuth]
            let data = jsonToData(json: json as AnyObject)!
            socket.write(dataTextFrame: data)
        }catch{
            print(error.localizedDescription)
        }
    }
}

