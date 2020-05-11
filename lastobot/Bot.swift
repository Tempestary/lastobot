//
// Created by milkavian on 5/9/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation


class Bot {
    let welcomeText = """
                      Я - бот-ласточка и я помогу тебе поиграть в спортивное ЧГК в условиях самоизоляции в том формате, в каком многие привыкли играть.
                      Что для этого нужно? 
                      1) Чат со мной для ведущего и групповой или приватный чат со мной для каждой из команд-участниц.
                      2) Ведущему необходимо создать одну большую видеоконференцию со всеми участниками игры таким образом, 
                      чтобы войс был только у ведущего - чтобы все участники видели друг друга, но слышали только ведущего.
                      3) Каждой команде при этом необходимо также создать видеоконференцию для участников, 
                      где команда будет обсуждать вопрос, а также командный icq-чат или приватный icq-чат со мной - я буду принимать ответы.
                      4) Ведущий создает новую игру, в беседе со мной нажав на кнопку "начать игру", и получает id игры, который раздает капитанам команд для присоединения к сессии игры.
                      5) Команда присоединяется к игре, нажав на кнопку "присоединиться к игре" или вызвав команду "/joingame"' в чате со мной. 
                      Когда я попрошу, в ответном сообщении необходимо будет указать id игры и название команды-участника в кавычках, например: 666 "Любимый голубь Хитчкока"
                      6) Ведущий получает от меня сообщения о том, какие команды зарегистрировались, и, когда все в сборе, нажимает на кнопку "Задать первый вопрос".
                      7) Когда все в сборе, ведущий зачитывает вопрос, после чего нажимает на кнопку "Задать первый вопрос". Нумерация вопросов начинается с 1.
                      Через 55 секунд я напомню игрокам о необходимости отправить ответ.
                      Команды могут ответить через команду "/answer ответ".
                      8) Ведущий получит от меня ответы всех команд в формате "номер вопроса - название команды - ответ"
                      9) Для окончания игры ведущему необходимо нажать на кнопку "закончить игру" или вызвать команду /finish.
                      """
    var lastEventId = 0
    let apiHandler: IcqApiHandler!
    let gameModel: GameModel!

    init() {
        apiHandler = IcqApiHandler()
        gameModel = GameModel()
    }

    func run() {
        fetchEvents()
    }

    private func handleEvent(event: Event) {
        dump(event.payload)
        switch event.payload {
        case .newMessage(let data):
            let text = splitStringIntoCommandAndArguments(text: data.text, argumentCount: 2)
            handleCommand(chatId: data.chat.chatId, command: text[0], arguments: text.count < 2 ? nil : text[1])

        case .callbackQuery(let data):
            let chatData = data.message.chat
            switch data.callbackData {
            case .rules:
            sendMessage(chatId: chatData.chatId, text: "\(welcomeText)", buttons: [BotCommands.startgame : "Новая игра",
                                                                                    BotCommands.join : "Присоединиться к игре",
                                                                                    BotCommands.help : "Помощь",
            ])
            case .start:
                if gameModel.hasActiveGame(userId: data.from.userId) {
                    sendMessage(chatId: chatData.chatId, text: "Похоже, у тебя есть незавершенная игра. Пожалуйста, заверши ее перед тем, как создавать новую или присоединяться к игре", buttons: [
                        BotCommands.finish : "Закончить игру"])
                } else {
                    let gameNumber = gameModel.randomString(length: 9)
                    gameModel.createGame(ownerId: data.from.userId, gameNumber: gameNumber)
                    sendMessage(chatId: chatData.chatId, text: """
                                                               Игра создана! ID новой игры: \(gameNumber), ее нужно передать капитанам.
                                                               Я сообщу тебе, когда команды начнут присоединяться к игре. После того, как все команды соберутся, жми "Задать первый вопрос".
                                                               """, buttons: [BotCommands.teamsready : "Задать первый вопрос",
                                                                              BotCommands.finish : "Закончить игру"]) 
                }
            case .finish:
                let usersToNotify = gameModel.finishGame(forOwnerId: data.from.userId)
                for user in usersToNotify {
                    sendMessage(chatId: user, text: "Игра успешно закончена. Похлопаем ведущему и ласточке - и можно играть заново!", buttons: [BotCommands.startgame : "Начать новую игру",
                                                                                                                                                BotCommands.join : "Присоединиться к игре"])
                }
            case .join:
                sendMessage(chatId: chatData.chatId, text: #"""
                                                           Для присоединения к игре выполните в чате команду
                                                            "/join id teamName" (без кавычек)
                                                           где вместо id укажите присланный ведущим id игры, а вместо teamName - название команды без кавычек, например
                                                           /join l337ftw Любимый Кальмар Коздимы
                                                           """#, buttons: [BotCommands.help : "Помощь"])

            case .teamsready, .setquestiontimer:
                let teamsToNotify = gameModel.teamsToNotify(ownerId: data.from.userId)
                let question = gameModel.getCurrentQuestion(userId: data.from.userId)
                gameModel.incrementQuestionNumber(userId: data.from.userId)
                let timer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { timer in
                    for team in teamsToNotify {
                        self.sendMessage(chatId: team, text: "Вопрос \(question). Осталось 10 секунд. Для отправки ответа выполните команду /answer ответ",
                            buttons: [BotCommands.answer: "Ответить"])
                    }
                    timer.invalidate()
                }
                timer.fire()
//                for team in teamsToNotify {
//                    sendMessage(chatId: team, text: "Вопрос \(question). До сбора ответов осталось 5 секунд. Для отправки ответа выполните команду #/answer ответ#",
//                        buttons: [BotCommands.answer: "Ответить"])
//                }


            default:
                sendMessageToUser(message: TextMessage(text: "Я вас услышал", buttons: [], chatId: chatData.chatId))
            }
        default:
            break
        }
    }

    private func sendMessage(chatId: String, text: String, buttons: [BotCommands : String]? = nil ) {
        if let buttons = buttons {
            var buttonData: [Button] = []
            for (callback, message) in buttons {
                let button = Button(text: message, callbackData: callback)
                buttonData += [button]
            }
            sendMessageToUser(message:TextMessage(text: text, buttons: [buttonData], chatId: chatId))

            return
        }
        sendMessageToUser(message:TextMessage(text: text, buttons: [], chatId: chatId))
}

    private func sendMessageToUser(message: TextMessage) {
        apiHandler.sendText(
            message: message,
            completion: { result in
                switch result {
                case .success (let data):
                    print("success", data)
                case .failure (let error):
                    print("error", error.localizedDescription)
                }
            }
        )
    }

    private func fetchEvents() {
        apiHandler.getEvents(lastEventId: lastEventId, completion: { result in
            switch result {
            case .success(let events):
                guard let latestEvent = events.last else {
                    break
                }

                self.lastEventId = latestEvent.id

                events.forEach(self.handleEvent)
            case .failure:
                return
            }

            self.fetchEvents()
        })
    }

    private func splitStringIntoCommandAndArguments(text: String, argumentCount: Int) -> [String] {
        return text.split(separator: " ", maxSplits: (argumentCount - 1)).map(String.init)
    }

    private func handleCommand(chatId: String, command: String, arguments: String?) {
        let command = BotCommands(rawValue: command)

        switch command {
        case .start:
            sendMessage(chatId: chatId, text: """
                                              Привет! Создай игру или присоединись к существующей! Полные правила игры смотри по кнопке Правила.
                                              """,
                    buttons: [BotCommands.startgame : "Новая игра", BotCommands.join : "Присоединиться к игре", BotCommands.rules : "Правила", BotCommands.help : "Помощь",
                    ])
        case .startgame:
            if gameModel.hasActiveGame(userId: chatId) {
                sendMessage(chatId: chatId, text: "Похоже, у тебя есть незавершенная игра. Пожалуйста, заверши ее перед тем, как создавать новую или присоединяться к игре", buttons: [
                    BotCommands.finish : "Закончить игру"])
            } else {
                let gameNumber = gameModel.randomString(length: 9)
                gameModel.createGame(ownerId: chatId, gameNumber: gameNumber)
                sendMessage(chatId: chatId, text: """
                                                           Игра создана! ID новой игры: \(gameNumber), ее нужно передать капитанам.
                                                           Я сообщу тебе, когда команды начнут присоединяться к игре. После того, как все команды соберутся, жми "Задать первый вопрос".
                                                           """, buttons: [BotCommands.teamsready : "Задать первый вопрос",
                                                                          BotCommands.finish : "Закончить игру"])
        }
        case .join:
            guard let arguments = arguments else {
                sendMessage(chatId: chatId, text: """
                                                  Для команды /join требуются два аргумента - id игры и название команды, например 
                                                  /join l337ftw Любимый Кальмар Коздимы
                                                  """)
                return
            }
            let args = splitStringIntoCommandAndArguments(text: arguments, argumentCount: 2)
            guard args.count > 1 else  {
                sendMessage(chatId: chatId, text: """
                                                  Для команды /join требуются два аргумента - id игры и название команды, например 
                                                  /join l337ftw Любимый Кальмар Коздимы
                                                  """)
                return
            }
            guard let team = gameModel.addTeamToTheGame(gameId: args[0], teamId: chatId, teamName: args[1]) else {
                sendMessage(chatId: chatId, text: "Не удалось добавить вас к игре: игры с таким id не существует или она завершена")
                return
            }
            sendMessage(chatId: chatId, text: "Вы в игре! Как только все команды соберутся, ведущий зачитает первый вопрос, а я помогу собрать ответы.")
            sendMessage(chatId: gameModel.getOwnerById(gameId: args[0])!, text: "Команда \(team.name) вступила в игру", buttons: [BotCommands.teamsready : "Задать первый вопрос",
                                                                                                                                   BotCommands.finish : "Закончить игру"])
        case .finish:
            if gameModel.hasActiveGame(userId: chatId) {
                let usersToNotify = gameModel.finishGame(forOwnerId: chatId)
                for user in usersToNotify {
                    sendMessage(chatId: user, text: "Игра успешно закончена. Похлопаем ведущему и ласточке - и можно играть заново!", buttons: [BotCommands.start : "Начать новую игру",
                                                                                                                                                BotCommands.join : "Присоединиться к игре"])
                }
            } else {
                sendMessage(chatId: chatId, text: "Похоже, у тебя нет незавершенных игр.", buttons: [
                    BotCommands.start : "Начать новую игру"])
            }

        case .answer:
            guard let arguments = arguments else {
                sendMessage(chatId: chatId, text: """
                                                  Для команды /answer требуется аргумент, например 
                                                  /answer Танос
                                                  Разрешается передавать в аргументы несколько слов
                                                  """)
                return
            }
            let args = splitStringIntoCommandAndArguments(text: arguments, argumentCount: 1)
            guard let currentGame = gameModel.getTeamGame(teamId: chatId) else {
                sendMessage(chatId: chatId, text: "Не удалось найти вашу активную игру. Возможно, вы не вступали в игровую сессию или игра была завершена")
                return
            }
        sendMessage(chatId: currentGame.owner, text: "Вопрос \(currentGame.question - 1) - \(currentGame.teams.filter { $0.id == chatId}.map { $0.name } ) - \(args[0])",
            buttons: [BotCommands.setquestiontimer: "Следующий вопрос", BotCommands.finish: "Закончить игру",])
        sendMessage(chatId: chatId, text: #"Вы ответили "\#(args[0])" на вопрос \#(currentGame.question - 1). Отправлено."#)

        default:
            sendMessage(chatId: chatId, text: "Неизвестная команда", buttons: [BotCommands.help : "Помощь"])
        }
    }
}