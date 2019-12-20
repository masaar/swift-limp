//
//  Limp.swift
//  ns-limp-rxswift
//
//  Created by Usman Mughal on 17/12/2019.
//  Copyright © 2019 Usman Mughal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public enum CredentialType:String {
    case username
    case email
    case phone
}

public struct ResponseArguments {
    
    public var call_id : String?
    public var docs : [Any]?
    public var count : Int?
    public var total : Int?
    public var groups : Any?
    public var code : String?
    public var _id : String?
    public var r_Session: [String:Any]?
    
    public var watch: String?
    public var user: [String:Any]?
    public var host_add: String?
    public var user_agent: String?
    public var timestamp: String?
    public var expiry: String?
    public var token: String?
}

public struct SocketResponse {
    public var args: ResponseArguments?
    public var msg: String?
    public var status: Int?
}

public protocol LimpDelegate: class {
    func didDisconnect(error:Error?)
    func didReceive(_ result:Bool, response:SocketResponse)
}

public class SDKConfig {
    public static var nonToken = "__ANON_TOKEN_f00000000000000000000012"
    public static var API_URL = "wss://limp-sample-app.azurewebsites.net/ws"
    public static var authHashLevel = 5.6
    public static var authAttrs: [String]?
    
    public init() {
    }
    
}

open class Limp: NSObject {
    
    static fileprivate let _shared = Limp()
    open class func API() -> Limp {
        return _shared
    }
    public var delegate: LimpDelegate?

//    var queue = (noAuth: Array<(Subject: Array<Observable<Any>> , callArgs: CallArguments)>() ,
//                 auth :  Array<(Subject: Array<Observable<Any>> , callArgs: CallArguments)>())
    
    var heartbeat = Observable<Int>.interval(.seconds(30), scheduler: MainScheduler.instance)
    var appActive = true
    
    var inited = false
   public var inited$ = BehaviorSubject<Bool>(value: false)
    var session = ResponseArguments(r_Session:nil)
    
    var authed = false
   public var authed$ = BehaviorSubject<ResponseArguments>(value: ResponseArguments.init())
    var nonToken: String?
    let header = Header(alg: "HS256", typ: "JWT")
    var socket : WebSocket?
    var reachability: Reachability!
    public let disposeBag = DisposeBag()
    
    

    
    private func setListener(listener: @escaping (Observable<(Bool, SocketResponse)>) -> ()) {
        
        socket?.onDisconnect = { (error: Error?) in
            // TODO: Handle error internally
            self.delegate?.didDisconnect(error: error)
            let success = Observable.just(false)
            let response = Observable.just(SocketResponse(args: nil, msg: nil, status: nil))
            let result = Observable.combineLatest(success,response)
            listener(result)
        }
        socket?.onText = { (text: String) in
            self.convertStringToJson(text: text, completion: { (json) in
                if let jsonValue = json {
                    
                    //For socketResponse:
                    let status = jsonValue["status"] as? Int
                    let msg = jsonValue["msg"] as? String
                    let arg = jsonValue["args"] as? [String:Any]
                    let code = arg?["code"] as? String
                    
                    //Details
                    let call_id = arg?["call_id"] as? String
                    let watch = arg?["watch"] as? String
                    let docs = arg?["docs"] as? [Any]
                    let count = arg?["count"] as? Int
                    let total = arg?["total"] as? Int
                    let groups = arg?["groups"]
                    
                    let session = arg?["session"] as? [String:Any]
                    let _id = session?["_id"]  as? String
                    let timestamp = session?["timestamp"] as? String
                    let token = session?["token"] as? String
                    let host_add = session?["host_add"] as? String
                    let expiry = session?["expiry"] as? String
                    let user_agent = session?["user_agent"] as? String
                    let user = session?["user"] as? [String:Any]
                    
                    let args = ResponseArguments(call_id: call_id, docs: docs, count: count, total: total, groups: groups, code: code, _id: _id, r_Session: session, watch: watch, user: user, host_add: host_add, user_agent: user_agent, timestamp: timestamp, expiry: expiry, token: token)
                    
                    let response = SocketResponse(args: args, msg: msg, status: status)
                    self.delegate?.didReceive(true, response: response)
                    let success = Observable.just(true)
                    let res = Observable.just(response)
                    let result = Observable.combineLatest(success,res)
                    listener(result)
                    
                    if (response.args?.code == "CORE_CONN_READY") {
                        self.reset()
                        self.nonToken = SDKConfig.nonToken
                        let callargs = CallArguments(endpoint: "conn/verify", authed: self.authed,
                                                     query: nil)
                        self.call(callArgs: callargs) { observer in
                            observer.asObservable().subscribe(onNext: { (success , response) in
                                let success = Observable.just(success)
                                let response = Observable.just(response)
                                let result = Observable.combineLatest(success,response)
                                listener(result)
                            }, onError: { error in
                                print(error)
                            }, onCompleted: {

                            }).disposed(by: self.disposeBag)
                        }
                    }
                    else if (response.args?.code == "CORE_CONN_OK"){
                        self.inited = true
                        self.inited$.onNext(true)
                        self.checkHeartbeat()
                    }
                    else if (response.args?.code == "CORE_CONN_CLOSED"){
                        self.reset()
                    }else if ((response.args?.r_Session) != nil){
                        print("Response has session obj")
                        let sid = response.args?.r_Session?["_id"] as? String
                        if (sid == "f00000000000000000000012") {
                            if (self.authed) {
                                self.authed = false
                                self.session.r_Session?.removeAll()
                                self.authed$.onNext(ResponseArguments(r_Session:nil))
                            }
                            self.removeCacheValue(key: "token")
                            self.removeCacheValue(key: "sid")
                            print("Session is null")
                        } else {
                            let token = response.args?.r_Session?["token"] as? String
                            let sid = response.args?.r_Session?["_id"] as? String
                            self.cacheValue(key: "token", value: token)
                            self.cacheValue(key: "sid", value: sid)
                            self.authed = true
                            self.session.r_Session = response.args?.r_Session
                            self.authed$.onNext(ResponseArguments(r_Session:self.session.r_Session))
                            print("Session updated")
                        }
                    }
                    
                    
                }else{
                    let response = SocketResponse(args: nil, msg: nil, status: nil)
                    self.delegate?.didReceive(true, response: response)
                    let success = Observable.just(true)
                    let res = Observable.just(response)
                    let result = Observable.combineLatest(success,res)
                    listener(result)
                }
            })
        }
        socket?.onData = { (data: Data) in
            // TODO: handle data response
            //             listener(true, SocketResponse(args: args, msg: msg, status: status)
            //            let response = data
            //                        let response = SocketResponse(args: args, msg: msg, status: status)
            //                        let success = Observable.just(true)
            //                        let result = Observable.just(response)
            //                        let final = Observable<Any>.combineLatest(success,result)
            //                        listener(final)
        }
        
        
    }
    
    open func checkHeartbeat(){
        self.inited$.asObserver().subscribe(onNext: { initt in
            if(initt){
                    self.heartbeat.asObservable().subscribe(onNext: { (i) in
                    print(i)
                    let callargs = CallArguments(endpoint: "heart/beat", authed: self.authed,
                                                 query: nil)
                    self.call(callArgs: callargs) { (observer) in
                        observer.asObservable().subscribe(onNext: { (success , response) in
                            print(success)
                            print(response)
                        }, onError: { error in
                            print(error)
                        }, onCompleted: {
                            
                        }).disposed(by: self.disposeBag)
                    }
                }, onError: { error in
                    print(error)
                }, onCompleted: {
                    print("heart beat complete..")
                    }).disposed(by: self.disposeBag)
            }
            
            /*
            if(!self.queue.noAuth.isEmpty){
                print("Found calls in noAuth queue:",self.queue.noAuth)
            }
            for call in self.queue.noAuth {
                Observable.combineLatest(call.Subject).asObservable().subscribe(onNext: { subject in
//                    let date = Date()
//                    let formatter = DateFormatter()
//                    let result = formatter.string(from: date)
//                    let tNow = (Float(result)! / 1000).rounded()
//                    let tEnd = (Float(result)! / 1000).rounded() + 86400
                }, onError: { error in
                    print(error)
                }, onCompleted: {
                    do {
                    var authJWT = JWT(header: self.header, payload: call.callArgs)
                    let token = JWTSigner.hs256(key: call.callArgs.token!.data(using: .utf8)!)
                    let sJWT = try authJWT.sign(using: token)
                    print("sending noAuth queue request as JWT token:" , call.callArgs , SDKConfig.nonToken)
                        let json: [String: Any] = [ "token": sJWT]
                        let data = self.jsonToData(json: json as AnyObject)!
                        self.socket?.write(dataTextFrame: data)
                    }catch{
                        print(error.localizedDescription)
                    }
                }).disposed(by: self.disposeBag)
            }
            
            self.queue.noAuth = []
            */
            
        }, onError: { error in
            print(error)
        }, onCompleted: {
            
        }).disposed(by: self.disposeBag)
        
        /*
        self.authed$.asObserver().subscribe(onNext: { (session) in
            if(session.r_Session != nil){
                if(!self.queue.auth.isEmpty){
                    print("Found calls in noAuth queue:",self.queue.auth)
                }
                for call in self.queue.auth {
                    print("processing auth call: ", call)
                    Observable.combineLatest(call.Subject).asObservable().subscribe(onNext: { subject in
                        //                    let date = Date()
                        //                    let formatter = DateFormatter()
                        //                    let result = formatter.string(from: date)
                        //                    let tNow = (Float(result)! / 1000).rounded()
                        //                    let tEnd = (Float(result)! / 1000).rounded() + 86400
                    }, onError: { error in
                        print(error)
                    }, onCompleted: {
                        do {
                            var authJWT = JWT(header: self.header, payload: call.callArgs)
                            let token = JWTSigner.hs256(key: call.callArgs.token!.data(using: .utf8)!)
                            let sJWT = try authJWT.sign(using: token)
                            print("sending noAuth queue request as JWT token:" , call.callArgs , SDKConfig.nonToken)
                            let json: [String: Any] = [ "token": sJWT]
                            let data = self.jsonToData(json: json as AnyObject)!
                            self.socket?.write(dataTextFrame: data)
                            
                        }catch{
                            print(error.localizedDescription)
                        }
                    }).disposed(by: self.disposeBag)
                }
                self.queue.auth = []
                
            }
            
        }, onError: { error in
            print(error)
        }, onCompleted: {
            
        }).disposed(by: self.disposeBag)
 
                 */
        
        let state = UIApplication.shared.applicationState
        if state == .background || state == .inactive {
            // background
            appActive = false
            heartbeat.asObservable().subscribe().dispose()
        } else if state == .active {
            // foreground
            appActive = true
        }

    }
    
    open func initilize(config:SDKConfig, completion: @escaping (Observable<(Bool, SocketResponse)>) -> ()) {
        
        if (SDKConfig.authAttrs?.count == 0){
            print("SDK Auth not set")
        }
        print("Resetting SDK before init.")
        self.reset()
        socket = WebSocket(url: URL(string: SDKConfig.API_URL)! )
        print("Attempting to connect.")
        setListener { observer in
            observer.asObservable().subscribe(onNext: { (success , response) in
                let success = Observable.just(success)
                let response = Observable.just(response)
                let result = Observable.combineLatest(success,response)
                completion(result)
                
            },onError: { error in
                print(error)
                self.reset(forceInited: true)
            }, onCompleted: {
                print("connection closed")
                self.reset()
            }
            ).disposed(by: self.disposeBag)
        }
        checkInternetStatus()
    }
    
    
    
    open func close(completion: @escaping (Observable<(Bool,SocketResponse)>) -> ()){
        
        let callargs = CallArguments(endpoint: "conn/close", authed: self.authed,
                                     query: nil)
        self.call(callArgs: callargs) { observer in
            observer.asObservable().subscribe(onNext: { (success , response) in
                let success = Observable.just(success)
                let response = Observable.just(response)
                let result = Observable.combineLatest(success,response)
                completion(result)
                
            }, onError: { error in
                print(error)
            }, onCompleted: {
                
            }).disposed(by: self.disposeBag)
        }
        
    }
    
    open func reset(forceInited:Bool = false){
        self.authed = false
        if (self.session.r_Session?.count != nil) {
            self.session.r_Session?.removeAll()
            self.authed = false
            self.authed$.onNext(ResponseArguments(r_Session:nil))
        }
            if (forceInited || inited) {
                self.inited = false
                self.inited$.onNext(false)
            }
    }
    
    
    open func call(callArgs:CallArguments, completion: @escaping(Observable<(Bool, SocketResponse)>) -> ()) {
        print("callArgs :",callArgs)
        do{
            var authJWT = JWT(header: header, payload: callArgs)
            let token = JWTSigner.hs256(key: callArgs.token!.data(using: .utf8)!)
            let finalHashAuth = try authJWT.sign(using: token)

      
            /*
            if ((self.inited && callArgs.awaitAuth! && self.authed) || (!self.inited && !callArgs.awaitAuth!) || callArgs.endpoint == "conn/verify") {
                Observable.combineLatest(filesSubjects).asObservable().subscribe(onNext: { subject in
                }, onError: { error in
                    print("Received error on fileSubject/filesSubjects: ",error)
                }, onCompleted: {
                    do {
                        var authJWT = JWT(header: self.header, payload: callArgs)
                        let token = JWTSigner.hs256(key: callArgs.token!.data(using: .utf8)!)
                        let sJWT = try authJWT.sign(using: token)
                        print("sending noAuth queue request as JWT token:" , callArgs , SDKConfig.nonToken)
                        let json: [String: Any] = [ "token": sJWT]
                        let data = self.jsonToData(json: json as AnyObject)!
                        self.socket?.write(dataTextFrame: data)
                    }catch{
                        print(error.localizedDescription)
                    }
                }).disposed(by: self.disposeBag)

            }else {
                print("SDK not yet inited. Queuing call:",callArgs)
                if callArgs.awaitAuth! {
                    print("Queuing in auth queue.")
                    self.queue.auth.append((filesSubjects,callArgs))

                }else {
                    print("Queuing in noAuth queue.")
                    self.queue.noAuth.append((filesSubjects,callArgs))
                }
            }
            */
            
            setListener { observer in
                observer.asObservable().subscribe(onNext: { (success , response) in
                    
                    if ((response.args != nil) && response.args?.call_id == callArgs.call_id) {
                        if let _id = callArgs.call_id {
                            print("message received from observer on call_id:" , _id)
                        }
                        if (response.status == 200) {
                            observer.subscribe(onNext: { (success , response) in
                            }).disposed(by: self.disposeBag)
                        }
                        if ((response.args?.watch) != nil) {
                            if let _id = response.args?.call_id{
                                print("completing the observer with call_id:",_id)
                            }
                        } else {
                            if let _id = response.args?.call_id{
                                print("Detected watch with call_id:",_id)
                            }
                        }
                    }
                    
                    let success = Observable.just(success)
                    let response = Observable.just(response)
                    let result = Observable.combineLatest(success,response)
                    completion(result)
                    
                }, onError: { error in
                    print(error.localizedDescription)
                }, onCompleted: {
                }
                ).disposed(by: self.disposeBag)
            }
            
            
            let json: [String: Any] = [ "token": finalHashAuth]
            let data = jsonToData(json: json as AnyObject)!
            socket?.write(dataTextFrame: data)
        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    private func checkInternetStatus()
    {
        reachability = Reachability()!
        NotificationCenter.default.addObserver(
            self,selector: #selector(networkStatusChanged(_:)),name: .reachabilityChanged,object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    @objc func networkStatusChanged(_ notification: Notification) {
        if reachability.connection != .none {
            if let connectionStatus = socket?.isConnected{
                if !connectionStatus {
                    socket?.connect()
                }
            }
            
        }
        
    }
    
    
    open func isAuthed() -> Any? {
        return session
    }
    
    open func deleteWatch(watch: String , completion:@escaping(Observable<(Bool, SocketResponse)>) -> ()){
        let watch =  SocketResponse().args?.watch ?? "__all"
        let json = CallArguments(endpoint: "watch/delete", authed: self.authed,
                                 query: [["watch" : watch]])
        self.call(callArgs: json) { observer in
            observer.asObservable().subscribe(onNext: { (success, response) in
                let success = Observable.just(success)
                let res = Observable.just(response)
                let result = Observable.combineLatest(success, res)
                completion(result)
            }, onError: { error in
                print(error)
            }, onCompleted: {
                
            }).disposed(by: self.disposeBag)
        }
    }
    
    func generateAuthHash(authVar: CredentialType, authVal: String, password: String) throws -> String {
        
        var hashObj = [authVar.rawValue, authVal, password];
        if SDKConfig.authHashLevel == 5.6 {
            hashObj.append(SDKConfig.nonToken)
        }
        var authJWT = JWT(header: header, payload: ["hash":hashObj])
        
        let token = JWTSigner.hs256(key: password.data(using: .utf8)!)
        let hash = try authJWT.sign(using: token)
        let smallHash = hash.components(separatedBy: ".")[1]
        return smallHash
    }
    
    open func auth(authVar:CredentialType, authVal:String, password:String, completion:@escaping(Observable<(Bool, SocketResponse)>) -> ()){
        do {
            if(SDKConfig.authAttrs?.firstIndex(of: authVar.rawValue) == -1){
                print("unkown authVar")
            }
            let hash = try generateAuthHash(authVar: authVar, authVal: authVal, password: password)
            let json = CallArguments(endpoint: "session/auth",
                                     authed: self.authed,
                                     doc: [authVar.rawValue:authVal,"hash" : hash])
            self.authed = false
            self.removeCacheValue(key: "token")
            self.removeCacheValue(key: "sid")
            self.session.r_Session = nil
            call(callArgs: json) { observer in
                observer.subscribe(onNext: { (success, response) in
                    let success = Observable.just(success)
                    let res = Observable.just(response)
                    let result = Observable.combineLatest(success,res)
                    completion(result)
                    self.authed = true
                    self.session.r_Session = response.args?.r_Session
                    let token = response.args?.r_Session?["token"] as? String
                    let sid = response.args?.r_Session?["_id"] as? String
                    self.cacheValue(key: "token", value: token)
                    self.cacheValue(key: "sid", value: sid)
                }, onError: { error in
                    print(error)
                }, onCompleted: {
                    
                }).disposed(by: self.disposeBag)
            }
            
        } catch {
            //handle error
            print(error)
            let success = Observable.just(false)
            let response = Observable.just(SocketResponse(args: nil, msg: error.localizedDescription, status: nil))
            let result = Observable.combineLatest(success,response)
            completion(result)
        }
    }
    
    
    open func reauth(completion: @escaping (Observable<(Bool, SocketResponse)>) -> ()){
        let cacheToken:String = self.getCachedValue(key: "token") ?? nonToken ?? ""
        let cacheSid:String = self.getCachedValue(key: "sid") ?? "f00000000000000000000012"
        do{
            var authJWT = JWT(header: header, payload: ["token":cacheToken])
            let token = JWTSigner.hs256(key: cacheToken.data(using: .utf8)!)
            let hash = try authJWT.sign(using: token)
            let smallHash = hash.components(separatedBy: ".")[1]
            let json = CallArguments(endpoint: "session/reauth", authed: self.authed,
                                     query: [["_id" :cacheSid , "hash" : smallHash]])
            
            
            call(callArgs: json) { observer in
                observer.subscribe(onNext: { (success , response) in
                    let success = Observable.just(success)
                    let response = Observable.just(response)
                    let result = Observable.combineLatest(success,response)
                    completion(result)
                }, onError: { error in
                    print(error)
                }, onCompleted: {
                    
                }).disposed(by: self.disposeBag)
            }
        }catch{
            let success = Observable.just(false)
            let response = Observable.just(SocketResponse(args: nil, msg: error.localizedDescription, status: nil))
            let result = Observable.combineLatest(success,response)
            completion(result)
        }
    }
    
    open func signout(completion: @escaping (Observable<(Bool,SocketResponse)>) -> ()){
        let cacheSid:String = self.getCachedValue(key: "sid") ?? "f00000000000000000000012"
        let json = CallArguments(endpoint: "session/signout",
                                 authed: self.authed,
                                 query: [["_id" :cacheSid]])
        call(callArgs: json) { observer in
            observer.subscribe(onNext: { (success , response) in
                let success = Observable.just(success)
                let response = Observable.just(response)
                let result = Observable.combineLatest(success,response)
                completion(result)
            }, onError: { error in
                print(error)
            },  onCompleted: {
                
            }).disposed(by: self.disposeBag)
        }
    }
    
    open func checkAuth(completion: @escaping (Observable<(Bool,SocketResponse)>) -> ()){
        let token = self.getCachedValue(key: "token")
        let sid = self.getCachedValue(key: "sid")
        if ((token == nil) || (sid == nil)){
            let success = Observable.just(false)
            let response = Observable.just(SocketResponse(args: nil, msg: "No credentials cached.", status: nil))
            let result = Observable.combineLatest(success, response)
            completion(result)
        }else{
            self.reauth { observer in
                observer.asObservable().subscribe(onNext: { (success , response) in
                    if response.status == 500 || response.status == 403 {
                        let success = Observable.just(false)
                        let response = Observable.just(SocketResponse(args: nil, msg: "Wrong credentials cached", status: 403))
                        let result = Observable.combineLatest(success, response)
                        completion(result)
                    }else {
                        self.authed = true
                        self.session.r_Session = response.args?.r_Session
                        let success = Observable.just(success)
                        let response = Observable.just(response)
                        let result = Observable.combineLatest(success, response)
                        completion(result)
                    }
                }, onError: { error in
                    print(error)
                }, onCompleted: {
                    
                }).disposed(by: self.disposeBag)
            }
        }
    }
    
    open func createFile(path:String, name:String, jobtitle:String, bio:String, completion:@escaping(Observable<(Bool, SocketResponse)>) -> ()){
        
        let callArgs = CallArguments(endpoint: "staff/create",
                                     authed:self.authed,
                                     doc: ["photo": Limp.API().createTravelFile(path),
                                           "name":["ar_AE":name],
                                           "jobtitle":["ar_AE":jobtitle],
                                           "bio":["ar_AE":bio],
        ])
        
        
        Limp.API().call(callArgs: callArgs) { observer in
            observer.asObservable().subscribe(onNext: { (success , response) in
                let success = Observable.just(success)
                let response = Observable.just(response)
                let result = Observable.combineLatest(success,response)
                completion(result)
            }, onError: { error in
                print(error)
            }, onCompleted: {
                
            }).disposed(by: self.disposeBag)
        }
    }
    
}


