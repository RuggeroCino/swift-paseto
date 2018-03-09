//
//  Token.swift
//  Paseto
//
//  Created by Aidan Woods on 08/03/2018.
//

import Foundation

infix operator <+: AdditionPrecedence

public struct Token {
    var claims: [String: String]
    var footer: String
    var allowedVersions: [Version]

    public init (
        claims: [String: String] = [:],
        footer: String = "",
        allowedVersions: [Version] = [.v2]
    ) {
        self.claims = claims
        self.footer = footer
        self.allowedVersions = allowedVersions
    }

    public subscript(key: String) -> String? {
        get { return claims[key] }
        set (value) { claims[key] = value }
    }

    public init (
        jsonData: Data, footer: String, allowedVersions: [Version]
    ) throws {
        guard let claims = try JSONSerialization.jsonObject(with: jsonData)
            as? [String: String]
        else {
            throw Exception.decodeError("Could not decode claims")
        }

        self.claims = claims
        self.footer = footer
        self.allowedVersions = allowedVersions
    }
}

public extension Token {
    public func replace(claims: [String: String]) -> Token {
        return Token(
            claims: claims,
            footer: footer,
            allowedVersions: allowedVersions
        )
    }

    public func replace(footer: String) -> Token {
        return Token(
            claims: claims,
            footer: footer,
            allowedVersions: allowedVersions
        )
    }

    public func replace(allowedVersions: [Version]) -> Token {
        return Token(
            claims: claims,
            footer: footer,
            allowedVersions: allowedVersions
        )
    }
}

public extension Token {
    public static func <+ (left: Token, right: [String: String]) -> Token {
        return left.replace(claims: left.claims <+ right)
    }
}

extension Token {
    var serialisedClaims: Data? {
        return try? JSONSerialization.data(withJSONObject: claims)
    }
}

public extension Token {
    func sign<V>(with key: AsymmetricSecretKey<V>) throws -> Blob<Signed> {
        guard let claimsData = serialisedClaims else {
            throw Exception.serialiseError(
                "The claims could not be serialised."
            )
        }

        guard allowedVersions.contains(Version(implementation: V.self)) else {
            throw Exception.disallowedVersion(
                "The version associated with the given key is not allowed."
            )
        }

        return V.sign(claimsData, with: key, footer: Data(footer.utf8))
    }

    func encrypt<V>(with key: SymmetricKey<V>) throws -> Blob<Encrypted> {
        guard let claimsData = serialisedClaims else {
            throw Exception.serialiseError(
                "The claims could not be serialised."
            )
        }

        guard allowedVersions.contains(Version(implementation: V.self)) else {
            throw Exception.disallowedVersion(
                "The version associated with the given key is not allowed."
            )
        }

        return V.encrypt(claimsData, with: key, footer: Data(footer.utf8))
    }
}

public extension Token {
    func sign<V>(with key: AsymmetricSecretKey<V>) -> Blob<Signed>? {
        return try? sign(with: key)
    }
    func encrypt<V>(with key: SymmetricKey<V>) -> Blob<Encrypted>? {
        return try? encrypt(with: key)
    }
}

public extension Token {
    enum Exception: Error {
        case serialiseError(String)
        case decodeError(String)
        case disallowedVersion(String)
    }
}
