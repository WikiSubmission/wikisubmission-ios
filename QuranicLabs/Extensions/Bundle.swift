import Foundation

extension Bundle {
  func decode<T: Decodable>(_ type: T.Type, from file: String, dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate, keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) -> T {
    guard let url = self.url(forResource: file, withExtension: nil) else {
      fatalError("Failed to locate \(file) in bundle.")
    }
    
    guard let data = try? Data(contentsOf: url) else {
      fatalError("Failed to load \(file) from bundle.")
    }
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = dateDecodingStrategy
    decoder.keyDecodingStrategy = keyDecodingStrategy
    
    do {
      return try decoder.decode(T.self, from: data)
    } catch DecodingError.keyNotFound(let key, let context) {
      fatalError("Failed to decode \(file) from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
    } catch DecodingError.typeMismatch(_, let context) {
      let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: ".")
      fatalError("Failed to decode \(file) from bundle due to type mismatch – Key: \(keyPath), \(context.debugDescription)")
    } catch DecodingError.valueNotFound(let type, let context) {
      let keyPath = context.codingPath.map { $0.stringValue }.joined(separator: ".")
      fatalError("Failed to decode \(file) from bundle due to missing \(type) value – \(context.debugDescription) [KEY: \(keyPath)]")
    } catch DecodingError.dataCorrupted(_) {
      fatalError("Failed to decode \(file) from bundle because it appears to be invalid JSON")
    } catch {
      fatalError("Failed to decode \(file) from bundle: \(error.localizedDescription)")
    }
  }
}
