//
//  AESCryptoService.swift
//  VaultShield
//
//  Created by Vivek Gopalan on 1/19/26.
//

import Foundation
import CryptoKit

struct AESCryptoService {
    private let saltLength = 16
    private let keyLength = 32 // AES-256
    private let version: UInt8 = 1

    // Encrypts a UTF-8 string with a master password.
    // Returns a Base64-encoded package: [version(1)] [salt(16)] [nonce+ciphertext+tag]
    func encrypt(text: String, password: String) throws -> String {
        guard !text.isEmpty else { throw CryptoError.emptyInput("Input") }
        guard !password.isEmpty else { throw CryptoError.emptyMasterPassword }

        let salt = randomData(count: saltLength)
        let key = try deriveKey(password: password, salt: salt)

        let plaintext = Data(text.utf8)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce)

        guard let combined = sealed.combined else {
            throw CryptoError.internalFailure("Unable to create combined sealed box.")
        }

        var package = Data()
        package.append(version)
        package.append(salt)
        package.append(combined)

        return package.base64EncodedString()
    }

    // Decrypts a Base64-encoded package created by encrypt(text:password:).
    func decrypt(base64Package: String, password: String) throws -> String {
        guard !base64Package.isEmpty else { throw CryptoError.emptyInput("Input") }
        guard !password.isEmpty else { throw CryptoError.emptyMasterPassword }

        guard let data = Data(base64Encoded: base64Package) else {
            throw CryptoError.invalidPackage("Base64 decoding failed.")
        }

        var cursor = 0

        // At minimum: version(1) + salt(16) + nonce(12) + tag(16)
        guard data.count > 1 + saltLength + 12 + 16 else {
            throw CryptoError.invalidPackage("Package too short.")
        }

        let pkgVersion = data[cursor]
        cursor += 1

        guard pkgVersion == version else {
            throw CryptoError.unsupportedVersion(pkgVersion)
        }

        let saltRange = cursor..<(cursor + saltLength)
        let salt = data.subdata(in: saltRange)
        cursor += saltLength

        let combined = data.subdata(in: cursor..<data.count)
        let key = try deriveKey(password: password, salt: salt)

        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: key)

        guard let string = String(data: decrypted, encoding: .utf8) else {
            throw CryptoError.invalidPlaintextEncoding
        }

        return string
    }

    // MARK: - Helpers

    private func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        let passwordData = Data(password.utf8)
        // HKDF-SHA256 key derivation from password and salt
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("VaultShield.AESGCM".utf8),
            outputByteCount: keyLength
        )
        return key
    }

    private func randomData(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        for i in 0..<count {
            bytes[i] = UInt8.random(in: UInt8.min...UInt8.max)
        }
        return Data(bytes)
    }

    enum CryptoError: LocalizedError {
        case emptyInput(String)
        case emptyMasterPassword
        case invalidPackage(String)
        case unsupportedVersion(UInt8)
        case invalidPlaintextEncoding
        case internalFailure(String)

        var errorDescription: String? {
            switch self {
            case .emptyInput(let field):
                return "\(field) cannot be empty."
            case .emptyMasterPassword:
                return "Master password cannot be empty."
            case .invalidPackage(let reason):
                return "Invalid encrypted package: \(reason)"
            case .unsupportedVersion(let v):
                return "Unsupported package version: \(v)"
            case .invalidPlaintextEncoding:
                return "Decrypted data is not valid UTF-8 text."
            case .internalFailure(let details):
                return "Internal error: \(details)"
            }
        }
    }
}
