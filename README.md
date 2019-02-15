
# Swift-limp

## Overview

This guide details how to integrate limp SDK into your iOS app. The iOS SDK is compatible with all iOS devices (iPhone, iPod, iPad) with iOS version 8 and above.

## Quick Start

### Download and add Limp SDK to Xcode
### Static Framework
•    Download the iOS SDK as a static framework
•    Unzip the Limp.framework.zip file you just downloaded
•    Drag the Limp.framework and drop it into your Xcode project
•    Make sure Copy items if needed is checked
•    Make sure  + in Embedded Binaries under TARGETS > General option in your xcode project

## SDK Initialization Swift

import  Limp Into your project To Access Public functions.

### Set Environment Variables 
```
TravelEnvironment.API_URL = “Your Server URL“.
TravelEnvironment.anonToken = “__ANONYMOUS_SECRET_TOKEN_f00000000000000000000012“.
```
### Initialization

Initial function to connect to websocket. Pass a closure as observer.
```
limp.API().initilize(TravelEnvironment.API_URL, nonToken: TravelEnvironment.anonToken) { (result, response) in
if result {
// Result is true means connection established successful.
}else {
// Some error happened on connection.
}
}
```

## SDK API Functions

### Authentication

There are three ways to authentication with server. There is enum with name CredentialType.
•    Email
•    Phone 
•    Username
Use password with one of the above to authenticate  with Server.

```
limp.API().auth(authVar: .email, authVal: “Your email“, password: “Your password”) { (success, response) in 
if success {
// Server call successful
}else {
// Some error happened.
}
}
```


### ReAuthentication

Limp  reauth using  token and  session id .
```
limp.API().reauth { (success, response) in
if success {
// Server call successful
}else {
// Some error happened.
}
}
```

### CheckAuth

To check whether user is already logged in  if not Reauth using current session id .

```
limp.API().checkAuth { (success, response) in
if success {
// Server call successful
}else {
// Some error happened.
}
}
```



### Logout

Logout expires your token and session id 

```
limp.API().signout { (success, response) in 
if success {
// Server call successful
}else {
// Some error happened.
}
}
```

### Call

Fetch data from server using call method that takes CallArguments. like Endpoints and query to identify server request, Which type of data you want to get.

```
let args = CallArguments(endpoint: “Your end poitns”, authed: true,
query: ["_id":["val”:”Document Id”]])
limp.API().call(callArgs: args) { (success, response) in
if success {
// Server call successful
}else {
// Some error happened.
}
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
