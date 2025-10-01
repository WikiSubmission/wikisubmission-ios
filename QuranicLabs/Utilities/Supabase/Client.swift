import Foundation
import Supabase
import Clerk

extension Utilities.Supabase {
    static var authenticatedClient = SupabaseClient(
      supabaseURL: URL(string: "https://uunhgbgnjwcdnhmgadra.supabase.co")!,
      supabaseKey: "sb_publishable_KPjPO6pfocS4xTwaoa4DXA_wSu9TMwW",
      options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
          accessToken: {
            try await Clerk.shared.session?.getToken()?.jwt
          }
        )
      )
    )
    
    static let anonClient = SupabaseClient(
      supabaseURL: URL(string: "https://uunhgbgnjwcdnhmgadra.supabase.co")!, 
      supabaseKey: "sb_publishable_KPjPO6pfocS4xTwaoa4DXA_wSu9TMwW"
    )
}
