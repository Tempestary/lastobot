//
// Created by milkavian on 5/10/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

struct Team {
    var id: String
    var name: String
}

struct Game {
    let id: String
    let owner: String
    var isFinished: Bool
    var teams: [Team]
    var question: Int
}