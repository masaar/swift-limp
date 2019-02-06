//
//  Header.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

import Foundation
public struct Header: Codable {
    
    /// Algorithm Header Parameter
    public var alg: String?
    /// Type Header Parameter
    public var typ: String?

    public init(
        alg: String? = nil,
        typ: String? = nil
        ) {
        self.alg = alg
        self.typ = typ
    }
    
    func encode() throws -> String  {
        let data = try JSONEncoder().encode(self)
        return data.base64urlEncodedString()
    }
}
extension Data {
    func base64urlEncodedString() -> String {
        let result = self.base64EncodedString()
        return result.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    init?(base64urlEncoded: String) {
        let paddingLength = 4 - base64urlEncoded.count % 4
        let padding = (paddingLength < 4) ? String(repeating: "=", count: paddingLength) : ""
        let base64EncodedString = base64urlEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + padding
        self.init(base64Encoded: base64EncodedString)
    }
}
