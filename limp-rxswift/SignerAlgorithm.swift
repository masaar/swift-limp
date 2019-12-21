//
//  SignerAlgorithm.swift
//  ns-limp-rxswift
//
//  Created by Usman Mughal on 17/12/2019.
//  Copyright © 2019 Usman Mughal. All rights reserved.
//

protocol SignerAlgorithm {
    /// A function to sign the header and claims of a JSON web token and return a signed JWT string.
    func sign(header: String, claims: String) throws -> String
}
protocol VerifierAlgorithm {
    func verify(jwt: String) -> Bool
    
}
