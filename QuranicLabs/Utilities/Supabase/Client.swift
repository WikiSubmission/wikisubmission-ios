import Foundation
import Supabase

extension Utilities.Supabase {
    static let client = SupabaseClient(
      supabaseURL: URL(string: "https://db.wikisubmission.org")!,
      supabaseKey: "sb_publishable_vffvRpUnrd1A9hQ21YlcQQ_OS3irtOa"
    )
}
