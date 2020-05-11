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

    func createGame(userId: String, gameNumber: String) {
        gamesBase["\(gameNumber)"] = Game(id: gameNumber, owner: userId, isFinished: false, teams: [], question: 1)
        print("ZZZ \(gamesBase)")
    }

    func finishGame(userId: String ) -> [String] {
        guard let game = getActiveGame(ownerId: userId) else {
            return []
        }
        let gameId = game.id
        gamesBase[gameId]!.isFinished = true
        var idsToNotify = gamesBase[gameId]!.teams.map { $0.id }
        idsToNotify += [gamesBase[gameId]!.owner]
        dump(gamesBase)
        return idsToNotify
    }
//    func teamsToNotify(gameId: String) -> [Team] {
//        return gamesBase[gameId]!.teams
//    }

    func hasActiveGame(userId: String) -> Bool {
        gamesBase.map { $0.value.owner }.contains( userId ) && gamesBase.map { $0.value.isFinished }.contains( false )
    }

    private func getActiveGame(ownerId: String) -> Game? {
        return gamesBase.values.first { $0.owner == ownerId && $0.isFinished == false }
    }

    private func isGameActive(gameId: String) -> Bool {
        return gamesBase[gameId]?.isFinished == false

//        let result = gamesBase.first { $0.key.contains(gameId)}
//        return result?.value.isFinished == false
    }

    func addTeamToTheGame(gameId: String, teamId: String, teamName: String) -> Team? {
        guard var currentGame = gamesBase[gameId], isGameActive(gameId: gameId) else {
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
