//
//  NFCReaderManager.swift
//  NFC Reader
//
//  Created by Edwin Ronald Velasquez Garcia on 27/02/23.
//

import Foundation
import CoreNFC

/**
 * A manager that an object implements to manage reading NFC Tag using NFCNDEFReaderSession
 */
public class NFCReaderManager: NSObject {
    public typealias DidRead = (NFCReaderManager, Result<String?, NFCReaderManagerError>) -> Void

    private var readerSession: NFCTagReaderSession?
    private var didRead: DidRead?
    
    public override init() { }
    
    public func readTag(didRead: @escaping DidRead) {
        guard NFCNDEFReaderSession.readingAvailable else {
            self.didRead?(self, .failure(.unavailable))
            return
        }
        let session = NFCTagReaderSession(pollingOption: [.iso14443, .iso15693, .iso18092], delegate: self)
        session?.alertMessage = "Acerca el tag para leer"
        beginSession(session: session, didRead: didRead)
    }
    
    private func beginSession(session: NFCTagReaderSession?,
                              didRead: @escaping DidRead) {
        guard session != nil else {
            invalidate(errorMessage: "Session nil")
            return
        }
        self.readerSession = session
        self.didRead = didRead
        session?.begin()
    }
    
    private func invalidate(errorMessage: String? = nil) {
        if errorMessage == nil {
            readerSession?.invalidate()
        } else {
            readerSession?.invalidate(errorMessage: errorMessage!)
        }
        readerSession = nil
        didRead = nil
    }
}

extension NFCReaderManager: NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let error = error as? NFCReaderError,
           error.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
            error.code != .readerSessionInvalidationErrorUserCanceled {
            self.didRead?(self, .failure(.invalidated(errorDescription: error.localizedDescription)))
        }
        self.readerSession = nil
        self.didRead = nil
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard tags.count > 0, let tag = tags.first else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(500)) {
                self.readerSession?.restartPolling()
            }
            return
        }
        session.connect(to: tag) { [weak self] error in
            guard let manager = self else { return }
            print(tag.isAvailable)
            if error != nil {
                manager.didRead?(manager, .failure(.invalidated(errorDescription: error!.localizedDescription)))
                manager.invalidate(errorMessage: error?.localizedDescription)
                return
            }
            switch tag {
            case .feliCa( _):
                print("feliCa")
            case .miFare( _):
                print("miFareTag")
            case .iso15693( _):
                print("iso15693")
            case .iso7816(let isoTag):
                let data = isoTag.identifier.map{String(format: "%.2hhx", $0)}.joined()
                manager.didRead?(manager, .success("Tag con identificador \(data)"))
                manager.invalidate()
            @unknown default:
                print("Invalid tag")
                manager.didRead?(manager, .failure(.notSupported))
                manager.invalidate()
            }
        }
    }
    
   
}
//extension NFCReaderManager: NFCNDEFReaderSessionDelegate {
//
//    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
//        if let error = error as? NFCReaderError,
//           error.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
//            error.code != .readerSessionInvalidationErrorUserCanceled {
//            self.didRead?(self, .failure(.invalidated(errorDescription: error.localizedDescription)))
//        }
//        self.readerSession = nil
//        self.didRead = nil
//    }
//    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
//       print(messages)
//    }
//
//    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
//        guard tags.count > 0, let tag = tags.first else {
//            DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(500)) {
//                self.readerSession?.restartPolling()
//            }
//            return
//        }
//        readerSessionConnect(session)(tag){ [weak self] error in
//            guard let readerManager = self else {return}
//            if error != nil {
//                readerManager.didRead?(readerManager, .failure(.invalidated(errorDescription: error!.localizedDescription)))
//                readerManager.invalidate(errorMessage: error?.localizedDescription)
//                return
//            }
//            tag.queryNDEFStatus { status, capacity, error in
//                switch status {
//                case .notSupported:
//                    readerManager.didRead?(readerManager, .failure(.notSupported))
//                    readerManager.invalidate(errorMessage: error?.localizedDescription)
//                case .readOnly, .readWrite:
//                    tag.readNDEF { message, error in
//                        if error != nil {
//                            readerManager.didRead?(readerManager, .failure(.invalidated(errorDescription: error!.localizedDescription)))
//                            readerManager.invalidate(errorMessage: error?.localizedDescription)
//                            return
//                        }
//                        readerManager.didRead?(readerManager, .success(message))
//                        readerManager.invalidate(errorMessage: error?.localizedDescription)
//                    }
//                default:
//                    readerManager.didRead?(readerManager, .failure(.generic))
//                    readerManager.invalidate(errorMessage: error?.localizedDescription)
//                }
//            }
//        }
//    }
//
//}
