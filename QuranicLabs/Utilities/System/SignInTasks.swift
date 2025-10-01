import Foundation
import Supabase
import Defaults
import Clerk

extension Utilities.System {
    static func signInTasks() async {
        // Refresh bookmarks
        if UserDefaults.standard.bool(forKey: Defaults.Keys.bookmarked_synced.name) == false {
            Task {
                try? await Utilities.Bookmarks.syncWithDatabase()
            }
        }
        
        // Refresh authenticated Supabase client
        Utilities.Supabase.authenticatedClient = SupabaseClient(
            supabaseURL: URL(string: "https://supabase.wikisubmission.org")!, supabaseKey: "sb_publishable_KPjPO6pfocS4xTwaoa4DXA_wSu9TMwW",
            options: SupabaseClientOptions(
              auth: SupabaseClientOptions.AuthOptions(
                accessToken: {
                  try await Clerk.shared.session?.getToken()?.jwt
                }
              )
            )
        )
    }
}
