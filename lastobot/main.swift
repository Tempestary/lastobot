//
//  main.swift
//  lastobot
//
//  Created by milkavian on 5/4/20.
//  Copyright © 2020 milonmusk. All rights reserved.
//

import Foundation

//apiHandler.getInfo(completion: { result in
//    switch result {
//    case .success (let data):
//        print("success", data)
//    case .failure (let error):
//        print("error", error.localizedDescription)
//    }
//})
//apiHandler.sendText(message: TextMessage(text: "превед рыс", buttons: [[Button(text: "Жми суда", callbackData: "fdgkdf;lgd")]], chatId: "752532504"),
//        completion: { result in
//    switch result {
//    case .success (let data):
//        print("success", data)
//    case .failure (let error):
//        print("error", error.localizedDescription)
//    }
//})

//
//var lastEventId = 0
//apiHandler.getEvents(lastEventId: lastEventId, completion: { result in
//    dump(result)
//
//    switch result {
//    case .success(let events):
//        guard let latestEvent = events.last else {
//            return
//        }
//        lastEventId = latestEvent.id
//    case .failure:
//        return
//    }
//})

let bot = Bot()
bot.run()

RunLoop.current.run()