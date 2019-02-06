//
//  Claims.swift
//  DemoWebSocket
//
//  Created by Usman Mughal on 31/01/2019.
//

protocol SignerAlgorithm {
    /// A function to sign the header and claims of a JSON web token and return a signed JWT string.
    func sign(header: String, claims: String) throws -> String
}
protocol VerifierAlgorithm {
    func verify(jwt: String) -> Bool
    
}
