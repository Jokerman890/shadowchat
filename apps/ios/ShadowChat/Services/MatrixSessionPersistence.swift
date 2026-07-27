import Foundation
@preconcurrency import KeychainAccess
import MatrixRustSDK
import Security

enum MatrixSessionPersistenceError: Error {
    case randomGenerationFailed(OSStatus)
    case missingApplicationDirectory
    case missingSession
}

struct MatrixSessionDirectories: Codable, Equatable, Sendable {
    let dataDirectory: URL
    let cacheDirectory: URL

    var dataPath: String {
        dataDirectory.path(percentEncoded: false)
    }

    var cachePath: String {
        cacheDirectory.path(percentEncoded: false)
    }

    static func create(fileManager: FileManager = .default) throws -> MatrixSessionDirectories {
        guard let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
        let caches = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw MatrixSessionPersistenceError.missingApplicationDirectory
        }

        let identifier = UUID().uuidString
        let dataDirectory = applicationSupport
            .appending(path: "Matrix", directoryHint: .isDirectory)
            .appending(path: identifier, directoryHint: .isDirectory)
        let cacheDirectory = caches
            .appending(path: "Matrix", directoryHint: .isDirectory)
            .appending(path: identifier, directoryHint: .isDirectory)

        try fileManager.createDirectory(
            at: dataDirectory,
            withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDataDirectory = dataDirectory
        var mutableCacheDirectory = cacheDirectory
        try mutableDataDirectory.setResourceValues(resourceValues)
        try mutableCacheDirectory.setResourceValues(resourceValues)

        return MatrixSessionDirectories(
            dataDirectory: dataDirectory,
            cacheDirectory: cacheDirectory
        )
    }

    func remove(fileManager: FileManager = .default) throws {
        for directory in [dataDirectory, cacheDirectory]
        where fileManager.fileExists(atPath: directory.path(percentEncoded: false)) {
            try fileManager.removeItem(at: directory)
        }
    }
}

struct MatrixRestorationToken: Codable, Sendable {
    let session: MatrixRustSDK.Session
    let directories: MatrixSessionDirectories
    let storePassphrase: String
}

extension MatrixRustSDK.Session: @retroactive Codable {
    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case userId
        case deviceId
        case homeserverUrl
        case oauthData = "oidcData"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self = try .init(
            accessToken: container.decode(String.self, forKey: .accessToken),
            refreshToken: container.decodeIfPresent(String.self, forKey: .refreshToken),
            userId: container.decode(String.self, forKey: .userId),
            deviceId: container.decode(String.self, forKey: .deviceId),
            homeserverUrl: container.decode(String.self, forKey: .homeserverUrl),
            oauthData: container.decodeIfPresent(String.self, forKey: .oauthData),
            slidingSyncVersion: .native
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encodeIfPresent(refreshToken, forKey: .refreshToken)
        try container.encode(userId, forKey: .userId)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(homeserverUrl, forKey: .homeserverUrl)
        try container.encodeIfPresent(oauthData, forKey: .oauthData)
    }
}

final nonisolated class MatrixSessionKeychain: ClientSessionDelegate, @unchecked Sendable {
    private let keychain: Keychain

    init(service: String = "de.shadowchat.ios.matrix.sessions") {
        keychain = Keychain(service: service)
            .accessibility(.afterFirstUnlockThisDeviceOnly)
    }

    func activeToken() throws -> MatrixRestorationToken? {
        guard let userID = keychain.allKeys().sorted().first,
              let data = try keychain.getData(userID) else {
            return nil
        }
        return try JSONDecoder().decode(MatrixRestorationToken.self, from: data)
    }

    func save(_ token: MatrixRestorationToken) throws {
        let encoded = try JSONEncoder().encode(token)
        try keychain.set(encoded, key: token.session.userId)
    }

    func removeActiveToken() throws {
        guard let userID = keychain.allKeys().sorted().first else {
            return
        }
        try keychain.remove(userID)
    }

    func retrieveSessionFromKeychain(userId: String) throws -> MatrixRustSDK.Session {
        guard let data = try keychain.getData(userId) else {
            throw MatrixSessionPersistenceError.missingSession
        }
        return try JSONDecoder()
            .decode(MatrixRestorationToken.self, from: data)
            .session
    }

    func saveSessionInKeychain(session: MatrixRustSDK.Session) {
        do {
            guard let data = try keychain.getData(session.userId) else {
                return
            }
            let current = try JSONDecoder().decode(MatrixRestorationToken.self, from: data)
            try save(
                MatrixRestorationToken(
                    session: session,
                    directories: current.directories,
                    storePassphrase: current.storePassphrase
                )
            )
        } catch {
            assertionFailure("Matrix session refresh could not be persisted: \(error)")
        }
    }
}

enum SecurePassphraseGenerator {
    static func make(byteCount: Int = 32) throws -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        guard status == errSecSuccess else {
            throw MatrixSessionPersistenceError.randomGenerationFailed(status)
        }
        return Data(bytes).base64EncodedString()
    }
}
