import Foundation
import Clerk
import SheetKit
import SwiftUI

extension Utilities.System {

    struct CanProceedResult {
        let success: Bool
        let failedCase: CanProceedCases?
        let reason: String?
    }

    static func ensureCanProceed(_ casesToCheck: [Utilities.System.CanProceedCases]) async -> CanProceedResult {
        for c in casesToCheck {
            do {
                let _ = try await c.performCheck()
            } catch let error as CanProceedCases.CheckError {
                return CanProceedResult(success: false, failedCase: c, reason: error.errorDescription)
            } catch {
                return CanProceedResult(success: false, failedCase: c, reason: error.localizedDescription)
            }
        }
        return CanProceedResult(success: true, failedCase: nil, reason: nil)
    }

    enum CanProceedCases {
        case ensureInternetConnection
        case ensureLoggedIn

        func performCheck() async throws -> Bool {
            switch self {
            case .ensureInternetConnection:
                let network = NetworkMonitor.shared
                guard network.hasInternet else { throw CheckError.noInternet }
                return true
            case .ensureLoggedIn:
                guard let _ = await Clerk.shared.user else { throw CheckError.notSignedIn }
                return true
            }
        }
        
        func presentErrorView() {
            switch self {
            case .ensureInternetConnection:
                SheetKit().presentWithEnvironment {
                    InternetRequiredContent()
                }
            case .ensureLoggedIn:
                SheetKit().presentWithEnvironment {
                    SignInRequiredContent()
                }
            }
        }

        enum CheckError: LocalizedError {
            case noInternet
            case notSignedIn

            var errorDescription: String? {
                switch self {
                case .noInternet: return "This feature requires an internet connection."
                case .notSignedIn: return "You must be signed in to access this feature."
                }
            }
        }
    }
}
