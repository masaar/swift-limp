//
//  Claims.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

import Foundation

public struct JWTSigner {
    
    /// The name of the algorithm that will be set in the "alg" header
    let name: String
    
    let signerAlgorithm: SignerAlgorithm

    init(name: String, signerAlgorithm: SignerAlgorithm) {
        self.name = name
        self.signerAlgorithm = signerAlgorithm
    }
    
    func sign(header: String, claims: String) throws -> String {
        return try signerAlgorithm.sign(header: header, claims: claims)
    }
    
    /// Initialize a JWTSigner using the HMAC 256 bits algorithm and the provided privateKey.
    public static func hs256(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS256", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha256))
    }
    
    /// Initialize a JWTSigner using the HMAC 384 bits algorithm and the provided privateKey.
    public static func hs384(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS384", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha384))
    }
    
    /// Initialize a JWTSigner using the HMAC 512 bits algorithm and the provided privateKey.
    public static func hs512(key: Data) -> JWTSigner {
        return JWTSigner(name: "HS512", signerAlgorithm: BlueHMAC(key: key, algorithm: .sha512))
    }
    
    /// Initialize a JWTSigner that will not sign the JWT. This is equivelent to using the "none" alg header.
    public static let none = JWTSigner(name: "none", signerAlgorithm: NoneAlgorithm())
    
}

