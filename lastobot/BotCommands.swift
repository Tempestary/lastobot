//
// Created by milkavian on 5/10/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

enum BotCommands: String, Codable {
    case startgame = "/startgame"
    case start = "/start"
    case startGamePressed = "startGamePressed"
    case joinGamePressed = "joinGamePressed"
    case join = "/join"
    case finishPressed = "finishPressed"
    case finish = "/finish"
    case helpPressed = "helpPressed"
    case help = "/help"
    case rulesPressed = "rulesPressed"
    case rules = "/rules"
    case teamsready = "teamsready"
    case answer = "/answer"
    case getactivegame = "/getactivegame"

    private enum CodingKeys: String, CodingKey {
        case startgame = "/startgame"
        case startGamePressed
        case joinGamePressed
        case joingame = "/joingame"
        case finishPressed
        case finish = "/finish"
        case helpPressed
        case help = "/help"
        case rulesPressed
        case rules = "/rules"
        case questionCountdownPressed
    }
}