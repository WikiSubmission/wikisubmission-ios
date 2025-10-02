import Foundation
import Supabase

extension Utilities.Supabase {
    static let anonClient = SupabaseClient(
      supabaseURL: URL(string: "https://uunhgbgnjwcdnhmgadra.supabase.co")!, 
      supabaseKey: "sb_publishable_KPjPO6pfocS4xTwaoa4DXA_wSu9TMwW"
    )
}
