//
//  Blob.swift
//  Paseto
//
//  Created by Aidan Woods on 05/03/2018.
//

import Foundation

public struct Blob<P: Payload> {
    let header: Header
    let payload: P
    public let footer: Data

    init (header: Header, payload: P, footer: Data = Data()) {
        self.header  = header
        self.payload = payload
        self.footer  = footer
    }

    public init? (_ string: String) {
        let parts = Header.split(string)

        guard [3, 4].contains(parts.count) else { return nil }

        guard let header  = Header(version: parts[0], purpose: parts[1]),
              let payload = P(encoded: parts[2])
        else { return nil }

        let footer: Data

        if parts.count > 3 { footer = Data(base64UrlNoPad: parts[3]) ?? Data() }
        else { footer = Data() }

        self.init(header: header, payload: payload, footer: footer)
    }
}

extension Blob {
    var asString: String {
        let main = header.asString + payload.encode
        guard !footer.isEmpty else { return main }
        return main + "." + footer.base64UrlNoPad
    }

    var asData: Data { return Data(self.asString.utf8) }
}

extension Blob where P == Signed {
    func verify<V>(with key: AsymmetricPublicKey<V>) throws -> Token {
        let message = try V.verify(self, with: key)
        return try token(jsonData: message)
    }
}

extension Blob where P == Encrypted {
    func decrypt<V>(with key: SymmetricKey<V>) throws -> Token {
        let message = try V.decrypt(self, with: key)
        return try token(jsonData: message)
    }
}

extension Blob {
    func token(jsonData: Data) throws -> Token {
        guard let footer = self.footer.utf8String else {
            throw Exception.badEncoding(
                "Could not convert the footer to a UTF-8 string."
            )
        }

        return try Token(
            jsonData: jsonData,
            footer: footer,
            allowedVersions: [header.version]
        )
    }
}

extension Blob {
    enum Exception: Error {
        case badEncoding(String)
    }
}
