//
// Created by milkavian on 5/10/20.
// Copyright (c) 2020 milonmusk. All rights reserved.
//

import Foundation

class GameModel {
    var gamesBase: [String : Game] = [:]

    init() {

    }
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    func createGame(ownerId: String, gameNumber: String) {
        gamesBase["\(gameNumber)"] = Game(id: gameNumber, owner: ownerId, isFinished: false, teams: [], question: 1)
        print("LOGIC: GAME \(gameNumber) STARTED")
    }

    func finishGame(forOwnerId: String ) -> [String] {
        guard let game = getActiveGame(ownerId: forOwnerId) else {
            return []
        }
        let gameId = game.id
        gamesBase[gameId]!.isFinished = true
        var idsToNotify = gamesBase[gameId]!.teams.map { $0.id }
        idsToNotify += [gamesBase[gameId]!.owner]
//        dump(gamesBase)
        print("LOGIC: GAME \(gameId) FINISHED")
        return idsToNotify
    }
    func teamsToNotify(ownerId: String) -> [String] {
        guard let game = getActiveGame(ownerId: ownerId) else {
            return []
        }
        let gameId = game.id
        let idsToNotify = gamesBase[gameId]!.teams.map { $0.id }
        return idsToNotify
    }

    func getCurrentQuestion(userId: String) -> Int {
        guard let game = getActiveGame(ownerId: userId) else {
            return 0
        }
        let gameId = game.id
        let currentQuestionNumber = gamesBase[gameId]!.question
        return currentQuestionNumber

    }

    func incrementQuestionNumber(userId: String) {
        guard let game = getActiveGame(ownerId: userId) else {
            return
        }
        let gameId = game.id
        gamesBase[gameId]!.question += 1
    }

    func hasActiveGame(userId: String) -> Bool {
        gamesBase.map { $0.value.owner }.contains( userId ) && gamesBase.map { $0.value.isFinished }.contains( false )
    }

    private func getActiveGame(ownerId: String) -> Game? {
        gamesBase.values.first { $0.owner == ownerId && $0.isFinished == false }
    }

    func getTeamGame(teamId: String) -> Game? {
        gamesBase.values.first { $0.teams.map { $0.id }.contains(teamId) && $0.isFinished == false }
    }

    private func isGameActive(gameId: String) -> Bool {
        gamesBase[gameId]?.isFinished == false
    }

    func addTeamToTheGame(gameId: String, teamId: String, teamName: String) -> Team? {
        guard let currentGame = gamesBase[gameId], isGameActive(gameId: gameId) else {
            return nil
        }

        let team = Team(id: teamId, name: teamName)

        gamesBase[gameId]!.teams += [team]
        print("ZZZZ gameBase: \(gamesBase), currentGame: \(currentGame)")
        return team
    }

    func getOwnerById(gameId: String) -> String? {
        guard let game = gamesBase[gameId] else {
            return nil
        }
        return game.owner
    }
}
