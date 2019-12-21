//
//  Updatable.swift
//  ns-limp-rxswift
//
//  Created by Usman Mughal on 17/12/2019.
//  Copyright © 2019 Usman Mughal. All rights reserved.
//


import Foundation

///
/// A protocol for calculations that can be updated with incremental data buffers.
///
public protocol Updatable {
    
    /// Status of the calculation.
    var status: Status { get }
    
    ///
    /// Low-level update routine.
    /// Updates the calculation with the contents of a data buffer.
    ///
    /// - Parameters:
     ///        - buffer:         Pointer to the data buffer
    ///     - byteCount:     Length of the buffer in bytes
    ///
    /// - Returns: `Self` if no error for optional chaining, nil otherwise
    ///
    func update(from buffer: UnsafeRawPointer, byteCount: size_t) -> Self?
}

///
/// Factors out common update code from Digest, HMAC and Cryptor.
///
extension Updatable {
    ///
    /// Updates the current calculation with data contained in an `NSData` object.
    ///
    /// - Parameter data: The `NSData` object
    ///
    /// - Returns: Optional `Self` or nil
    ///
    public func update(data: NSData) -> Self? {
        
        _ = update(from: data.bytes, byteCount: size_t(data.length))
        return self.status == .success ? self : nil
    }
    
    ///
    /// Updates the current calculation with data contained in an `Data` object.
    ///
    /// - Parameters data: The `Data` object
    ///
    /// - Returns: Optional `Self` or nil
    ///
    public func update(data: Data) -> Self? {
        
        _ = data.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>) in

            _ = update(from: buffer, byteCount: size_t(data.count))
        }
        return self.status == .success ? self : nil
    }
    
    ///
    /// Updates the current calculation with data contained in a byte array.
    ///
    /// - Parameter byteArray: The byte array
    ///
    /// - Returns: Optional `Self` or nil
    ///
    public func update(byteArray: [UInt8]) -> Self? {
        
        _ = update(from: byteArray, byteCount: size_t(byteArray.count))
        return self.status == .success ? self : nil
    }
    
    ///
    /// Updates the current calculation with data contained in a String.
    /// The corresponding data will be generated using UTF8 encoding.
    ///
    /// - Parameter string: The string of data
    ///
    /// - Returns: Optional `Self` or nil
    ///
    public func update(string: String) -> Self? {
        
        _ = update(from: string, byteCount: size_t(string.utf8.count))
        return self.status == .success ? self : nil
    }
}
