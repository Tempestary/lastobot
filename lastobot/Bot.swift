//
// Created by milkavian on 5/9/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation


class Bot {
    let welcomeText = """
                      Я - бот-ласточка и я помогу тебе поиграть в спортивное ЧГК в условиях самоизоляции в максимально привычном формате.
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
                      9) Для окончания игры ведущему необходимо нажать на кнопку "закончить игру" или вызвать команду /finish. Обязательно завершайте игровые сессии. 
                      """

    let startgameButton = Button(text: "Новая игра", callbackData: .start)
    let joinButton = Button(text: "Присоединиться к игре", callbackData: .join)
    let finishButton = Button(text: "Закончить игру", callbackData: .finish)
    let helpButton = Button(text: "Помощь", callbackData: .help)
    let rulesButton = Button(text: "Правила", callbackData: .rules)
    let teamsReadyButton = Button(text: "Задать первый вопрос", callbackData: .teamsready)
    let setQuestionTimerButton = Button(text: "Следующий вопрос", callbackData: .setquestiontimer)
    let answerButton = Button(text: "Помощь по команде /answer", callbackData: .answer)
    let fbButton = Button(text: "Оставить отзыв", callbackData: .fb)

    var lastEventId = 0
    let apiHandler: IcqApiHandler!
    let gameModel: GameModel!

    func sendStartMessage(chatId: String) {
        sendMessageToUser(message:TextMessage(text: "Привет! Создай игру или присоединись к существующей! Полные правила игры смотри по кнопке Правила",
            buttons: [[Button(text: "Новая игра", callbackData: .start), Button(text: "Присоединиться к игре", callbackData: .join)],
            [Button(text: "Правила", callbackData: .rules), Button(text: "Помощь", callbackData: .help)],
            [Button(text: "Оставить отзыв", callbackData: .fb)]],
            chatId: chatId))
    }

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
            handleCommand(chatId: data.chat.chatId, command: text[0], arguments: text.count < 2 ? nil : text[1], chatData: data)

        case .callbackQuery(let data):
            let chatData = data.message.chat
            switch data.callbackData {
            case .rules:
            sendMessage(chatId: chatData.chatId, text: "\(welcomeText)", buttons: [BotCommands.start : "Новая игра",
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
                if !gameModel.hasActiveGame(userId: data.from.userId) {
                    sendMessage(chatId: data.from.userId, text: "Похоже, у тебя нет активных игр. Чтобы что-то завершить, нужно что-то начать!", buttons: [BotCommands.start : "Начать новую игру",
                                                                                                                                                           BotCommands.join : "Присоединиться к игре"])
                    return
                } else {
                    let usersToNotify = gameModel.finishGame(forOwnerId: data.from.userId)
                    for user in usersToNotify {
                        sendMessage(chatId: user, text: "Игра успешно закончена. Похлопаем ведущему и ласточке - и можно играть заново!", buttons: [BotCommands.start: "Начать новую игру",
                                                                                                                                                    BotCommands.join: "Присоединиться к игре"])
                    }
                }
            case .join:
                sendMessage(chatId: chatData.chatId, text: #"""
                                                           Для присоединения к игре выполните в чате команду
                                                            "/join id teamName" (без кавычек)
                                                           где вместо id укажите присланный ведущим id игры, а вместо teamName - название команды без кавычек, например
                                                           /join l337ftw Любимый Кальмар Коздимы
                                                           """#, buttons: [BotCommands.help : "Помощь"])

            case .teamsready, .setquestiontimer:
                if gameModel.hasActiveGame(userId: chatData.chatId) {
                    let teamsToNotify = gameModel.teamsToNotify(ownerId: data.from.userId)
                    let question = gameModel.getCurrentQuestion(userId: data.from.userId)
                    gameModel.incrementQuestionNumber(userId: data.from.userId)

                    self.sendMessage(chatId: chatData.chatId, text: "Вопрос \(question). Таймер запущен. Через 50 секунд я напомню командам о необходимости ответа.")

                    DispatchQueue.main.async {
                        let timer = Timer.scheduledTimer(withTimeInterval: 50.0, repeats: false) { timer in
                            for team in teamsToNotify {
                                self.sendMessage(chatId: team, text: """
                                                                     До сбора ответов сталось 10 секунд. Для отправки ответа выполните команду 
                                                                     /answer ответ
                                                                     """,
                                    buttons: [BotCommands.answer: "Помощь по команде /answer"])

                            }
                            self.sendMessage(chatId: chatData.chatId, text: "Вопрос \(question). До конца таймера вопроса 10 секунд. На написание и отправку ответа команде дается еще 10 секунд.")
                        }
                        let _ = Timer.scheduledTimer(withTimeInterval: 70.0, repeats: false) { _ in
                            self.sendMessage(chatId: chatData.chatId, text: "Ответы на вопрос \(question) больше не принимаются. Команды все еще могут их отправить, решение принимает Ведущий.")
                        }
                    }
                } else {
                    sendMessage(chatId: chatData.chatId, text: "Ой-ой, у тебя нет активной игры. Начни игру, чтоб задавать вопросы или присоединись к игре, чтоб отвечать на вопросы!", buttons: [
                        BotCommands.start : "Начать новую игру", BotCommands.join : "Присоединиться к игре"])
                }
            case .help:
                sendMessage(chatId: chatData.chatId, text: """
                                                           Команды, которые я поддерживаю:
                                                           /start - эта команда запускает меня
                                                           /stop - а эта останавливает
                                                           /startgame - создает новую игру с уникальным id
                                                           /join arg1 arg2 - присоединиться к активной игре с именем команды(может состоять из нескольких слов), пример: /join 5ycIfmdD Салатные листья с Плутона
                                                           /answer arg1 - ответить на текущий вопрос, пример: /answer котята. Допускается несколько слов в аргументе.
                                                           /finish - закончить активную игру, выполняется от имени создателя игры. Пожалуйста, не забывайте завершать свои активные игры!
                                                           /help - показать этот мануал
                                                           /rules - показать правила карантинного ЧГК
                                                           /fb arg1 - отправить отзыв обо мне или предложение
                                                           """)

            case .answer:
                sendMessage(chatId: chatData.chatId, text: """
                                                           Для ответа вызовите команду /answer ответ, например 
                                                           /answer Танос
                                                           Разрешается передавать в аргументы несколько слов
                                                           """)
            case .fb:
                sendMessage(chatId: chatData.chatId, text: #"Для отправки отзыва или предложения, пожалуйста, напишите команду "/fb отзыв", без кавычек. Я передам пожелания и предложения разработчику."#)
            default:
                sendMessage(chatId: chatData.chatId, text: "42, потому что 404 - это слишком избито.")

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
        text.split(separator: " ", maxSplits: (argumentCount - 1)).map(String.init)
    }

    private func handleCommand(chatId: String, command: String, arguments: String?, chatData: NewMessagePayload? = nil) {
        let command = BotCommands(rawValue: command)

        switch command {
        case .start:
//            sendMessage(chatId: chatId, text: """
//                                              Привет! Создай игру или присоединись к существующей! Полные правила игры смотри по кнопке Правила.
//                                              """,
//                    buttons: [BotCommands.start : "Новая игра", BotCommands.join : "Присоединиться к игре", BotCommands.rules : "Правила", BotCommands.help : "Помощь",
//                    ])
            sendStartMessage(chatId: chatId)
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
                sendMessage(chatId: chatId, text: "Похоже, у тебя нет активных игр. Чтобы что-то завершить, нужно что-то начать!", buttons: [
                    BotCommands.start : "Начать новую игру", BotCommands.join : "Присоединиться к игре"])
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
        case .fb:
            guard let arguments = arguments else {
                sendMessage(chatId: chatId, text: "Я не могу отправить пустой отзыв :(")
                return
            }
            let args = splitStringIntoCommandAndArguments(text: arguments, argumentCount: 1)
            guard let chatData = chatData, let firstName = chatData.from.firstName else {
                sendMessage(chatId: "752532504", text: "Отзыв от UID \(chatId): \(args[0])")
                return
            }
            sendMessage(chatId: "752532504", text: "Отзыв от UID \(chatData.from.userId) (\(firstName)): \(args[0])")
            sendMessage(chatId: chatId, text: "Отзыв отправлен. Спасибо! Если я понадоблюсь - просто вызовите команду /start в чате.")
        case .help:
            sendMessage(chatId: chatId, text: """
                                                       Команды, которые я поддерживаю:
                                                       /start - эта команда запускает меня
                                                       /stop - а эта останавливает
                                                       /startgame - создает новую игру с уникальным id
                                                       /join arg1 arg2 - присоединиться к активной игре с именем команды(может состоять из нескольких слов), пример: /join 5ycIfmdD Салатные листья с Плутона
                                                       /answer arg1 - ответить на текущий вопрос, пример: /answer котята. Допускается несколько слов в аргументе.
                                                       /finish - закончить активную игру, выполняется от имени создателя игры. Пожалуйста, не забывайте завершать свои активные игры!
                                                       /help - показать этот мануал
                                                       /rules - показать правила карантинного ЧГК
                                                       /fb - отправить отзыв обо мне или предложение
                                                       """)
        default:
            return
//            sendMessage(chatId: chatId, text: "Неизвестная команда", buttons: [BotCommands.help : "Помощь"])
//        sendStartMessage(chatId: chatId)
        }
    }
}