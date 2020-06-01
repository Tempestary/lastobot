//
// Created by milkavian on 5/4/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum NetworkError: Error {
    case url
    case server
    case badJson
}

class IcqApiHandler {

    let apiUrl = URL(string: "https://api.icq.net/bot/v1/")
    let botToken = ProcessInfo.processInfo.environment["LASTOBOT_TOKEN"] // live bot
    let session = URLSession.shared
    let timeout: Float = 20.0

    func getInfo(completion: @escaping (Result<Data, NetworkError>) -> Void) {
        sendRequest(httpMethod: "GET", endpoint: "self/get", params: [:], body: [:], completion: completion)
    }

    func getEvents(lastEventId eventId: Int, completion: @escaping (Result<[Event], NetworkError>) -> Void) {
        sendRequest(
                httpMethod: "GET", 
                endpoint: "events/get",
                params: [
                    "lastEventId": eventId,
                    "pollTime": 10
                ],
                body: [:],
                completion: { result in
                    switch result {
                    case .success(let data):
                            do {
                                let result = try JSONDecoder().decode(GetEventsResult.self, from: data)
                                completion(.success(result.events))
                            } catch {
                                print("JSON ERROR: \(error.localizedDescription)")
                                completion(.failure(.badJson))
                            }
                    case .failure(let error):
                        print("NETWORK GET EVENTS ERROR: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
        )
    }

    func sendText(message: TextMessage, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        sendRequest(
            httpMethod: "POST",
            endpoint: "messages/sendText",
            params: [
                "chatId": message.chatId,
                "text": message.text,
            ],
            body: message.buttons.count > 0 ? ["inlineKeyboardMarkup": message.buttons.map { $0.map {
                [
                    "text": "" + $0.text,
                    "callbackData": "" + $0.callbackData.rawValue,
                ]
            }}] : [:],
            completion: completion
        )
    }

    func callbackAnswer(queryId: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        sendRequest(
            httpMethod: "GET",
            endpoint: "messages/answerCallbackQuery",
            params: [
                "queryId": queryId
            ],
            body: [:],
            completion: completion)
    }

    private func sendRequest(httpMethod: String, endpoint: String, params: [String: CustomStringConvertible?],
                             body: [String: Codable], completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var paramsWithToken = params
        paramsWithToken["token"] = botToken

        guard let url = buildUrl(endpoint: endpoint, params: paramsWithToken) else {
            return completion(.failure(.url))
        }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        request.httpBody = try? bodyBuilder(body: body)
        self.sendRequest(request: request, retryNumber: 0, completion: completion)
    }

    private func sendRequest(request: URLRequest, retryNumber: Int, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("NETWORK SEND REQUEST ERROR: \(error.localizedDescription), retrying for the \(retryNumber+1) time")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
                    self.sendRequest(request: request, retryNumber: retryNumber+1, completion: completion)
                })
                return
            }
            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(.server))
            }
        }.resume()
    }

    private func buildUrl(endpoint: String, params: [String: CustomStringConvertible?]) -> URL? {
        guard let url = URL(string: endpoint, relativeTo: apiUrl), var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        let items = params.compactMap { pair -> URLQueryItem? in
            guard let value = pair.value else {
                return nil
            }

            return URLQueryItem(name: pair.key, value: value.description)
        }

        components.queryItems = items
        return components.url
    }

    private func bodyBuilder(body: [String: Codable?]) throws -> Data? {
        var urlComponents = URLComponents()
        urlComponents.queryItems = try body.compactMap { pair -> URLQueryItem? in
            guard let value = pair.value else {
                return nil
            }
            let jsonedValue = try JSONSerialization.data(withJSONObject: value)

            return URLQueryItem(name: pair.key, value: String(decoding: jsonedValue, as: UTF8.self))
        }
        return urlComponents.query?.data(using: .utf8)
    }
}