
# limp-rxSwift

Official ReactiveX Swift SDK for LIMP.

## Quick Start

### Install limp-rxSwift for ReactiveX

You need to add following pods into your target before integrating Limp SDK.
For iOS version 9 and above.

```
pod 'RxSwift', '~> 5'
pod 'RxCocoa', '~> 5'
```
## Installing

### Download and add Limp SDK to Xcode
### Static Framework
•    Download the iOS SDK as a static framework
•    Unzip the Limp.framework.zip file you just downloaded
•    Drag the Limp.framework and drop it into your Xcode project
•    Make sure Copy items if needed is checked
•    Make sure  + in Embedded Binaries under TARGETS > General option in your xcode project

## How to Use

### Initializing 

import limp-rxSwift Into your project To Access Public functions.

You need to call initializer with SDKConfig object to connect to websocket. Pass a observer as closure.

```
Limp.API().initilize(config:SDKConfig()) { observer in
observer.asObservable().subscribe(onNext: { (success , response) in
	// server call response
}, onError: { (error) in
    // some error happened.
}, onCompleted: {
    
}).disposed(by: self.disposeBag)
}
```

### SDK Config

When initialising the SDK, you should pass an object matching the interface SDKConfig, which has the following attributes:

api (Required): The URI of LIMP app you are connecting to.
anonToken (Required): LIMP app ANON_TOKEN.
authAttrs (Required): As of LIMP APIv5.8, LIMP apps don't have strict User module attrs structure. This includes the authentication attrs that are set per app. This attribute represents an [String]? referring to the same authentication attrs of the app.
authHashLevel (Optional): Either 5.0 or 5.6. With the change to auth hash generation introduced in APIv5.6 of LIMP, some legacy apps are left without the ability to upgrade to APIv5.6 and beyond due to hashes difference. SDKv5.7 is adding authHashLevel to allow developers to use higher APIs and SDKs with legacy apps. Default 5.6;

## Best Practices 

You can use the SDK 100% per your style of development, however we have some tips:

### Session Reauth

The best practice to handle a reauth scenario is by attempting to checkAuth as soon as the connection with LIMP app is made. This can be made by subscribing to inited$ subject which notifies subscriptions about any changes to SDK initialisation status reflected as inited attribute in the SDK. Which can be done like:

```
Limp.API().inited$.asObserver().subscribe(onNext: { (init) in
if(init){
	// SDK is inited and ready for your calls:
	Limp.API().checkAuth { (Observable<(Bool, SocketResponse)>) in
	    // server call response
	}
}
}, onError: { error in
	   // some error happened.
}, onCompleted: {

}).disposed(by: self.disposeBag)
}

```

### Auth State Detection

Although, you can detect the user auth state in the subscription of the calls auth, reauth and checkAuth, the best practice is to use the global authed$ state Subject. You can do this by subscripting to authed$ in the same component (usually AppComponent) you are initiating the SDK at. This assures a successful checkAuth as part of the api.init subscription can be handled. The model suggested is:

```
Limp.API().authed$.asObserver().subscribe(onNext: { (responseArguments) in
    if(responseArguments.r_Session != nil){
        print("We are having an `auth` condition with session:",responseArguments.r_Session)
    }else{
        print("We just got unauthenticated")
    }
}, onError: { (error) in
    // some error happened.
}, onCompleted: {
    
}).disposed(by: self.disposeBag)
```

### Reconnecting on Disconnects

Websockets are always-alive connections. A lot can go wrong here resulting in the connection with your LIMP app. To make sure you can always get reconnected recall SDK init method upon SDK becoming not inited:

```
Limp.API().inited$.asObserver().subscribe(onNext: { (initt) in
if(initt){
    // SDK is inited and ready for your calls:
    Limp.API().checkAuth { (Observable<(Bool, SocketResponse)>) in
 	// server call response
    }else {
    Limp.API().initilize(config: SDKConfig()) { (Observable<(Bool, SocketResponse)>) in
    // server call response
        }
    }
}
}, onError: { error in
    // some error happened.
}, onCompleted: {

    }).disposed(by: self.disposeBag)
```

## API Reference

### session 

A Response Argument object representing the current session. It has value only when the user is authenticated.

### authed 

A boolen storing the current state of user authentication.

### authed$

A BehaviorSubject<ResponseArguments> you can subscribe to handle changes to state of user authentication.

### init()

The base method to initiate a connection with LIMP app. This method returns an Observable for chain subscription if for any reason you need to read every message being received from the API, however subscribing to it is not required. Method definition:

```
Limp.API().initilize(config: SDKConfig()) { (Observable<(Bool, SocketResponse)>) in
// server call reponse 
}
```

### close()

The method to close current connection with LIMP app. This method returns an Observable for chain subscription if for any reason you need to read the resposne of the close call, however subscribing to it is not required. Method definition:

```
Limp.API().close { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### auth()

The method you can use to authenticate the user. This method returns an Observable for chain subscription if for any reason you need to read the response of the auth call, however subscribing to it is not required. Method definition:

```
Limp.API().auth(authVar: String, authVal: String, password: String) { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### reauth()
The method you can use to reauthenticate the user. The method would fail if no sid and token attrs are cached from earlier successful authentication call. This method returns an Observable for chain subscription if for any reason you need the response of the reauth call, however subscribing to it is not required. Method definition:

```
Limp.API().reauth { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### Signout()

The method you can use to signout the current user. Upon success, this methods removes all the cached attrs of the session. This method returns an Observable for chain subscription if for any reason you need the response of the signout call, however subscribing to it is not required. Method definition:

```
Limp.API().signout { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### CheckAuth()

The method to check whether there is a cached session and attempt to reauthenticate the user. This method would return an error if no credentials are cached. This method returns an Observable for chain subscription if for any reason you need the response of the checkAuth call, however subscribing to it is not required. Method definition:

```
Limp.API().checkAuth { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### generateAuthHash()

The method to use to generate authentication hashes. This is used internally for the auth() call. However, you also need this to generate the values when creating a user. Method definition:

```generateAuthHash(CredentialType authVar, String authVal , String password){/*...*/}```

### deleteWatch()

The method to delete a watch in progress. You can pass the watch ID you want to delete or ```__all``` to delete all watches. This method returns an Observable for chain subscription if for any reason you need the response of the deleteWatch call, however subscribing to it is not required. Method definition:

```
Limp.API().deleteWatch(watch: "__all") { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}
```

### Call 

The most important method in the SDK. This is the method you use to call different endpoints in your LIMP app. Although the callArgs object in the params is having full definition of all call attrs, you still usually only need to pass either query and/or doc in most of the cases. Method definition:

```
let callArgs = CallArguments(Endpoints, false, query, doc);
Limp.API().call(callArgs: callArgs) { (Observable<(Bool, SocketResponse)>) in
//server call repsonse
}

```

## Using Delegates

Limp  also provides delegates methods to track when connections Lost and when user some received Response from Server . 
LimpDelegate offers two delegates Protocols to conform :

### didDisconnect 

Get called When user disconnect from Server 
```
func didDisconnect(_ result: Bool, error: Error?) {
if result {
// Server Disconected  successful
}else {
// Some error happened.
}
}
```

### didReceive

Receive Response  from server on every  Call functions  mentioned above. 

```
func didReceive(_ result: Bool, response: SocketResponse) {
if result {
// Server call successful
}else {
// Some error happened.
}
}
```
