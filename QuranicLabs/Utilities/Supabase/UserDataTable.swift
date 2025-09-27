import Foundation
import PostgREST

extension Utilities.Supabase {
    struct UserDataTable {
        static func getUserBookmarks() async throws -> [Types.Supabase.Bookmarks] {
            do {
                let response = try await Utilities.Supabase.client
                    .from("ws-user-data")
                    .select("quran_bookmarks")
                    .execute()
                
                return decodeBookmarkData(response).sorted { $0.created_at > $1.created_at }
            } catch {
                print("Error listing bookmarks", error.localizedDescription)
                throw error
            }
        }
        
        static func updateUserBookmarks(_ bookmarks: [Types.Supabase.Bookmarks]) async throws {
            do {
                let _: PostgrestResponse<Void> = try await Utilities.Supabase.client
                    .from("ws-user-data")
                    .upsert(["quran_bookmarks": bookmarks])
                    .execute()
            } catch {
                print("Error updating bookmarks", error.localizedDescription)
                throw error
            }
        }
        
        private static func decodeBookmarkData(_ data: PostgrestResponse<Void>?) -> [Types.Supabase.Bookmarks] {
            let string = data?.string()
            
            guard let string = string,
                  let data = string.data(using: .utf8) else {
                return []
            }

            struct Wrapper: Decodable {
                let quran_bookmarks: [Types.Supabase.Bookmarks]
            }

            do {
                let wrappers = try JSONDecoder().decode([Wrapper].self, from: data)
                return wrappers.flatMap { $0.quran_bookmarks }
            } catch {
                print("Error decoding bookmark data", error.localizedDescription)
                return []
            }
        }
    }
}
