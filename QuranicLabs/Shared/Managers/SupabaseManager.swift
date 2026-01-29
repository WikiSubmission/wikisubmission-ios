import SwiftUI
import Supabase
import Defaults
import Security
import Foundation

class SupabaseManager: ObservableObject {
    
    static let shared = SupabaseManager()
    static let url = URL(string: "https://db.wikisubmission.org")!
    static let publishableKey = "sb_publishable_vffvRpUnrd1A9hQ21YlcQQ_OS3irtOa"
    static let client = SupabaseClient(
        supabaseURL: SupabaseManager.url,
        supabaseKey: SupabaseManager.publishableKey,
        options: SupabaseClientOptions(
            auth: .init(
                storage: KeychainStorage()
            )
        )
    )
    
    @Published var session: Session? = nil
        
    init() {
        Task {
            for await (event, newSession) in SupabaseManager.client.auth.authStateChanges {
                print("Auth event: \(event.rawValue)")
                
                switch event {
                case .initialSession, .signedIn, .tokenRefreshed:
                    await MainActor.run {
                        self.session = newSession
                        if let _ = self.session?.user {
                           Task {
                               try await SupabaseManager.client.auth.update(user: .init(
                                data: .init([
                                    "platform":"ios",
                                    "version": About.version
                                ])
                               ))
                           }
                           Task {
                               try? await NotificationManager.shared.sync()
                           }
                        } else {
                            print("No user session")
                        }
                    }

                case .signedOut:
                    await MainActor.run {
                        self.session = nil
                    }

                default:
                    break
                }
            }
        }
        
        // Optional: If no session after a short delay (fallback, rare)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            if self.session == nil {
                do {
                    _ = try await SupabaseManager.client.auth.signInAnonymously()
                    print("Fallback: Signed in anonymously")
                } catch {
                    print("Fallback anonymous sign-in failed: \(error)")
                }
            }
        }
    }
    
    @MainActor
    func requireSession() async throws -> Session {
        // 1. Already resolved
        if let session {
            return session
        }

        // 2. Check immediately available cached session
        if let current = SupabaseManager.client.auth.currentSession {
            self.session = current
            return current
        }

        // 3. Await auth state resolution (initialSession / signedIn)
        for await (event, newSession) in SupabaseManager.client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed:
                if let resolved = newSession {
                    self.session = resolved
                    return resolved
                }
            default:
                break
            }
        }

        // 4. Absolute fallback
        let newSession = try await SupabaseManager.client.auth.signInAnonymously()
        self.session = newSession
        return newSession
    }
}

struct PushNotificationsUser: Encodable {
    let user_id: UUID
    let updated_at: String?
    let device_token: String
    let platform: String
    let version: String
    let enabled: Bool
}

struct PushNotificationsRegistryPrayerTimes: Encodable {
    let user_id: UUID
    let updated_at: String?
    let device_token: String
    let enabled: Bool
    let location: String?
    let afternoon_midpoint_method: Bool
    let dawn: Bool
    let noon: Bool
    let afternoon: Bool
    let sunset: Bool
    let night: Bool
    let sunrise: Bool
}

struct PushNotificationsRegistryDailyVerse: Encodable {
    let user_id: UUID
    let updated_at: String?
    let device_token: String
    let enabled: Bool
}

struct PushNotificationsRegistryRandomVerse: Encodable {
    let user_id: UUID
    let updated_at: String?
    let device_token: String
    let enabled: Bool
}

struct PushNotificationsRegistryAnnouncements: Encodable {
    let user_id: UUID
    let updated_at: String?
    let device_token: String
    let enabled: Bool
}

struct KeychainStorage: AuthLocalStorage {
    
    func store(key: String, value: Data) throws {
        // First remove any existing item with this key (to overwrite)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Now add the new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
    
    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { return nil }
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
        
        return item as? Data
    }
    
    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
        }
    }
}
