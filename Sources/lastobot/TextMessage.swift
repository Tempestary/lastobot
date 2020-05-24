//
// Created by milkavian on 5/4/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

struct Button: Codable {
    var text: String
    var callbackData: BotCommands
}

struct TextMessage: Codable {
    var text: String
    var buttons: [[Button]]
    var chatId: String
}