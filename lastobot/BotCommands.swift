//
// Created by milkavian on 5/10/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

enum BotCommands: String, Codable {
    case startgame = "/startgame"
    case start = "/start"
    case join = "/join"
    case finish = "/finish"
    case help = "/help"
    case rules = "/rules"
    case teamsready = "teamsready"
    case setquestiontimer = "/setquestiontimer"
    case answer = "/answer"
    case getactivegame = "/getactivegame"
    case questionWithMedia = "questionWithMedia"
    case sendfeedback = "/sendfeedback"

    private enum CodingKeys: String, CodingKey {
        case startgame = "/startgame"
        case joingame = "/joingame"
        case finish = "/finish"
        case help = "/help"
        case rules = "/rules"
    }
}