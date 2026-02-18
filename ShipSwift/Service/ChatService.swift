//
//  ChatService.swift
//  ShipSwift
//
//  Handles communication with the ShipSwift Chat API backend.
//  Sends user messages and receives AI responses with optional component IDs.
//
//  Created by Wei Zhong on 18/2/26.
//

import Foundation

// MARK: - Chat Response Model

/// Response from the POST /api/chat endpoint.
struct ChatResponse: Decodable {
    let reply: String
    let component: String?
}

// MARK: - Chat Service

/// Communicates with the ShipSwift backend chat API.
///
/// The backend proxies requests to OpenAI GPT and returns a text reply
/// along with an optional component ID when a matching SwiftUI component is found.
struct ChatService {
    private let endpoint = URL(string: "https://api.shipswift.app/api/chat")!

    /// Build the history array for the API request from existing messages.
    private func buildHistory(from messages: [ChatMessage]) -> [[String: String]] {
        messages.compactMap { message in
            // Skip component preview messages (they add no meaningful context for LLM)
            if message.componentId != nil { return nil }
            return [
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ]
        }
    }

    /// Send a message to the chat API and return the response.
    /// - Parameters:
    ///   - message: The user's message text
    ///   - history: Previous messages for context
    /// - Returns: ChatResponse with reply text and optional component ID
    func send(message: String, history: [ChatMessage]) async -> ChatResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "message": message,
            "history": buildHistory(from: history)
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return ChatResponse(
                    reply: "Sorry, I couldn't reach the server. Please try again later.",
                    component: nil
                )
            }

            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            swDebugLog("[ChatService] Error: \(error.localizedDescription)")
            return ChatResponse(
                reply: "Something went wrong. Please try again.",
                component: nil
            )
        }
    }
}
