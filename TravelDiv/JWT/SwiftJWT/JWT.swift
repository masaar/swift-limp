//
//  JWT.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

import Foundation

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
