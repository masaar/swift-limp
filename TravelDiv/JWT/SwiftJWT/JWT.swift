//
//  JWT.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

import Foundation
//public struct JWT : Codable {
//
//    /// The JWT header.
//    public var header: Header = Header()
//    /// The JWT claims
//    public var claims: Claims = Claims()
//
//    public init(header: Header = Header(), claims: Claims) {
//        self.header = header
//        self.claims = claims
//    }
//
//    public init(from decoder: Decoder) throws {
//    }
//
//    public func encode(to encoder: Encoder) throws {
//    }
//
//    public mutating func sign(using jwtSigner: JWTSigner) throws -> String {
//        var tempHeader = header
//        tempHeader.alg = jwtSigner.name
//        let headerString = try tempHeader.encode()
//        let claimsString = try claims.encode()
//        header.alg = tempHeader.alg
//        return try jwtSigner.sign(header: headerString, claims: claimsString)
//    }
//}


public struct JWT<Payload> where Payload: Codable {
    /// The headers linked to this message
    public var header: Header
    
    /// The JSON payload within this message
    public var payload: Payload
    
    /// Creates a new JSON Web Signature from predefined data
    public init(header: Header = .init(), payload: Payload) {
        self.header = header
        self.payload = payload
    }
    
    public mutating func sign(using jwtSigner: JWTSigner) throws -> String {
        var tempHeader = header
        tempHeader.alg = jwtSigner.name
        let headerString = try tempHeader.encode()
        let jsonEncoder = JSONEncoder()
        let payloadData = try jsonEncoder.encode(self.payload)
        let encodedPayload = payloadData.base64urlEncodedString()
        header.alg = tempHeader.alg
        return try jwtSigner.sign(header: headerString, claims: encodedPayload)
    }

    
}
