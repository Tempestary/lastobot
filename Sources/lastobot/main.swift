//
//  main.swift
//  lastobot
//
//  Created by milkavian on 5/4/20.
//  Copyright © 2020 milonmusk. All rights reserved.
//

import Foundation

let bot = Bot()
bot.run()

RunLoop.current.run()

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}