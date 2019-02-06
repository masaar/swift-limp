//
//  Claims.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

import Foundation

class BlueHMAC: SignerAlgorithm, VerifierAlgorithm {
    let name: String = "HMAC"
    
    private let key: Data
    private let algorithm: HMAC.Algorithm
    
    init(key: Data, algorithm: HMAC.Algorithm) {
        self.key = key
        self.algorithm = algorithm
    }
    
    func sign(header: String, claims: String) throws -> String {
        let unsignedJWT = header + "." + claims
        guard let unsignedData = unsignedJWT.data(using: .utf8) else {
            throw JWTError.invalidJWTString
        }
        let signature = try sign(unsignedData)
        let signatureString = signature.base64urlEncodedString()
        return header + "." + claims + "." + signatureString
    }
    
    func sign(_ data: Data) throws -> Data {
        guard #available(macOS 10.12, iOS 10.0, *) else {
            print("macOS 10.12.0 (Sierra) or higher or iOS 10.0 or higher is required by Cryptor")
            throw JWTError.osVersionToLow
        }
        guard let hmac = HMAC(using: algorithm, key: key).update(data: data)?.final() else {
            throw JWTError.invalidPrivateKey
        }
        return Data(bytes: hmac)
    }
    
    
    func verify(jwt: String) -> Bool {
        let components = jwt.components(separatedBy: ".")
        if components.count == 3 {
            guard let signature = Data(base64urlEncoded: components[2]),
                let jwtData = (components[0] + "." + components[1]).data(using: .utf8)
                else {
                    return false
            }
            return self.verify(signature: signature, for: jwtData)
        } else {
            return false
        }
    }
    
    func verify(signature: Data, for data: Data) -> Bool {
        guard #available(macOS 10.12, iOS 10.0, *) else {
            return false
        }
        do {
            let expectedHMAC = try sign(data)
            return expectedHMAC == signature
        }
        catch {
            print("Verification failed: \(error)")
            return false
        }
    }
}
