//
// Created by milkavian on 5/9/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

struct GetEventsResult: Decodable {
    let events: [Event]
}

enum EventType: String, Codable {
    case newMessage
    case callbackQuery
}

enum SenderType: String, Codable {
    case channel
    case group
    case `private`
}

struct NewMessagePayload: Codable {
    let msgId: String?
    let chat: Chat
    let from: From
    let timestamp: Int
    let text: String
//    let parts: [Parts]?
}

struct CallbackQueryPayload: Codable {
    let queryId: String
//    let chat: Chat?
    let message: NewMessagePayload
    let from: From
    let callbackData: BotCommands
}

struct Chat: Codable {
    let chatId: String
    let type: SenderType?
    let title: String?
}
struct From: Codable {
    let userId: String
    let firstName: String?
    let lastName: String?
}

struct Parts: Codable {
    let type: String?
    let payload: PartsPayload?
}

struct PartsPayload: Codable {
    let fileId: String?
}
enum Payload {
    case newMessage(NewMessagePayload)
    case callbackQuery(CallbackQueryPayload)
    case other
}

struct Event: Decodable {
    let id: Int
    let payload: Payload
}

extension Event {

    private enum CodingKeys: String, CodingKey {
        case eventId
        case payload
        case type
    }

    enum EventCodingError: Error {
        case decoding(String)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        guard let eventId = try? values.decode(Int.self, forKey: .eventId) else {
            throw EventCodingError.decoding("Whoops1! \(dump(values))")
        }

        self.id = eventId

        guard let type = try? values.decode(String.self, forKey: .type) else {
            throw EventCodingError.decoding("Whoops2! \(dump(values))")
        }

        switch type {
        case "newMessage":
            if let value = try? values.decode(NewMessagePayload.self, forKey: .payload) {
                self.payload = .newMessage(value)
                return
            }
        case "callbackQuery":
//            if let value = try? values.decode(CallbackQueryPayload.self, forKey: .payload) {
//                self.payload = .callbackQuery(value)
//                return
//            }
            let value = try values.decode(CallbackQueryPayload.self, forKey: .payload)
                self.payload = .callbackQuery(value)
                return

        default:
            self.payload = .other
            return
        }

        throw EventCodingError.decoding("Whoops3! \(dump(values))")
    }
}