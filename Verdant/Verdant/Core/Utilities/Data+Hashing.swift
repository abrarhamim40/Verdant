//
//  Data+Hashing.swift
//  Verdant
//
//  Created by Abrar Hamim on 5/17/26.
//

import Foundation
import CryptoKit

extension Data {
    /// SHA256 hex digest. Used as ResponseCache key so identical photos hit cache instead of paying for an API call.
    var sha256Hash: String {
        SHA256.hash(data: self)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
