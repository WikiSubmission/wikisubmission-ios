import Foundation
import Supabase
import Clerk

extension Utilities.Supabase {
    static let client = SupabaseClient(
      supabaseURL: URL(string: "https://uunhgbgnjwcdnhmgadra.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV1bmhnYmduandjZG5obWdhZHJhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcwMDA2ODczOCwiZXhwIjoyMDE1NjQ0NzM4fQ.h60-_iXuK5tNi4CfU2KCjYxLWkCNOo0V8itj-rue-dI",
      options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(
          accessToken: {
            try await Clerk.shared.session?.getToken()?.jwt
          }
        )
      )
    )
}
