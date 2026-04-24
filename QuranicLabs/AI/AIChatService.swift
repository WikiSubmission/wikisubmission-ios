import Foundation

struct AIChatReply: Decodable {
    let answer: String
    let sources: [String]

    private enum CodingKeys: String, CodingKey {
        case answer
        case sources
    }

    init(answer: String, sources: [String] = []) {
        self.answer = answer
        self.sources = sources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        answer = try container.decode(String.self, forKey: .answer)
        sources = try container.decodeIfPresent([String].self, forKey: .sources) ?? []
    }
}

enum AIChatError: LocalizedError {
    case notConfigured
    case invalidResponse
    case rateLimited
    case serverMessage(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI has not been configured yet."
        case .invalidResponse:
            return "The AI service returned an unexpected response."
        case .rateLimited:
            return "Too many requests right now. Please wait a moment and try again."
        case .serverMessage(let message):
            return message
        case .transport(let message):
            return message
        }
    }
}

enum AIChatConfiguration {
    static var endpointURL: URL? {
        if let configured = Bundle.main.object(forInfoDictionaryKey: "AIServiceURL") as? String,
           let url = URL(string: configured.trimmingCharacters(in: .whitespacesAndNewlines)),
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }

        return URL(string: "https://wikisubmission.org/api/ask")
    }

    static var modelLabel: String {
        let configured = (Bundle.main.object(forInfoDictionaryKey: "AIServiceLabel") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return configured?.isEmpty == false ? configured! : "WikiSubmission AI"
    }
}

final class AIChatService {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func send(question: String, conversationID: String?) async throws -> AIChatReply {
        guard let endpointURL = AIChatConfiguration.endpointURL else {
            throw AIChatError.notConfigured
        }

        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(AIChatRequest(
            question: question,
            conversationID: conversationID
        ))

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIChatError.invalidResponse
            }

            if httpResponse.statusCode == 429 {
                throw AIChatError.rateLimited
            }

            if !(200...299).contains(httpResponse.statusCode) {
                if let apiError = try? decoder.decode(AIChatErrorResponse.self, from: data),
                   !apiError.error.isEmpty {
                    throw AIChatError.serverMessage(apiError.error)
                }

                throw AIChatError.serverMessage("The AI service returned \(httpResponse.statusCode).")
            }

            guard let reply = try? decoder.decode(AIChatReply.self, from: data) else {
                throw AIChatError.invalidResponse
            }

            return reply
        } catch let error as AIChatError {
            throw error
        } catch let error as URLError {
            throw AIChatError.transport(Self.message(for: error))
        } catch {
            throw AIChatError.transport("Something went wrong while contacting the AI service.")
        }
    }

    private static func message(for error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "You appear to be offline."
        case .timedOut:
            return "The response took too long. Try a shorter or simpler question."
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return "The AI service is unavailable right now."
        default:
            return "Something went wrong while contacting the AI service."
        }
    }
}

private struct AIChatRequest: Encodable {
    let question: String
    let conversationID: String?

    enum CodingKeys: String, CodingKey {
        case question
        case conversationID = "conversation_id"
    }
}

private struct AIChatErrorResponse: Decodable {
    let error: String
}
