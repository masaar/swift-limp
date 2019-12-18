//
//  JWTError.swift
//  ns-limp-rxswift
//
//  Created by Usman Mughal on 17/12/2019.
//  Copyright © 2019 Usman Mughal. All rights reserved.
//

import Foundation

// MARK: JWTError

/// A struct representing the different errors that can be thrown by SwiftJWT
public struct JWTError: Error, Equatable {

    /// A human readable description of the error.
    public let localizedDescription: String
    
    private let internalError: InternalError
    
    private enum InternalError {
        case invalidJWTString, failedVerification, osVersionToLow, invalidPrivateKey, invalidData, invalidKeyID
    }
    
    /// Error when an invalid JWT String is provided
    public static let invalidJWTString = JWTError(localizedDescription: "Input was not a valid JWT String", internalError: .invalidJWTString)
    
    /// Error when the JWT signiture fails verification.
    public static let failedVerification = JWTError(localizedDescription: "JWT verifier failed to verify the JWT String signiture", internalError: .failedVerification)
    
    /// Error when using RSA encryption with an OS version that is too low.
    public static let osVersionToLow = JWTError(localizedDescription: "macOS 10.12.0 (Sierra) or higher or iOS 10.0 or higher is required by CryptorRSA", internalError: .osVersionToLow)
    
    /// Error when an invalid private key is provided for RSA encryption.
    public static let invalidPrivateKey = JWTError(localizedDescription: "Provided private key could not be used to sign JWT", internalError: .invalidPrivateKey)
    
    /// Error when the provided Data cannot be decoded to a String
    public static let invalidUTF8Data = JWTError(localizedDescription: "Could not decode Data from UTF8 to String", internalError: .invalidData)
    
    /// Error when the KeyID field `kid` in the JWT header fails to generate a JWTSigner or JWTVerifier
    public static let invalidKeyID = JWTError(localizedDescription: "The JWT KeyID `kid` header failed to generate a JWTSigner/JWTVerifier", internalError: .invalidKeyID)
    
    /// Function to check if JWTErrors are equal. Required for equatable protocol.
    public static func == (lhs: JWTError, rhs: JWTError) -> Bool {
        return lhs.internalError == rhs.internalError
    }
}
