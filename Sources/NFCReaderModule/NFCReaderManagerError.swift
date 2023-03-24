//
//  NFCReaderError.swift
//  NFC Reader
//
//  Created by Edwin Ronald Velasquez Garcia on 27/02/23.
//

import Foundation

/**
 * A type representing an error when NFC Tag is :
 *  - unavailable
 *  - not supported
 *  - invalidated
 *  - another error A.K.A. generic
 */
public enum NFCReaderManagerError: Error {
    case unavailable
    case notSupported
    case invalidated(errorDescription: String)
    case generic
}
