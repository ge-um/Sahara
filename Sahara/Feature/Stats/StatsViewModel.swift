//
//  StatsViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

struct BasicStats {
    let totalCards: Int
    let daysSinceStart: Int
    let thisMonthCards: Int
    let lastMonthDiff: Int
    let currentStreak: Int
}

struct MonthlyData {
    let month: String
    let count: Int
}

struct WeekdayData {
    let weekday: String
    let count: Int
}

struct TimeData {
    let timeOfDay: String
    let count: Int
}

struct MoodData {
    let mood: Mood
    let count: Int
}

final class StatsViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
    }

    struct Output {
        let basicStats: Driver<BasicStats>
        let monthlyData: Driver<[MonthlyData]>
        let weekdayData: Driver<[WeekdayData]>
        let timeData: Driver<[TimeData]>
        let moodData: Driver<[MoodData]>
        let weekdayInsight: Driver<String>
        let timeInsight: Driver<String>
        let thisMonthInsight: Driver<String>
    }

    func transform(input: Input) -> Output {
        let realm = try! Realm()

        let basicStatsDriver = input.viewWillAppear
            .map { _ -> BasicStats in
                let cards = realm.objects(Card.self)
                let totalCards = cards.count

                let daysSinceStart = self.calculateDaysSinceStart(cards: Array(cards))
                let thisMonthCards = self.calculateThisMonthCards(cards: Array(cards))
                let lastMonthDiff = self.calculateLastMonthDiff(cards: Array(cards))
                let currentStreak = self.calculateCurrentStreak(cards: Array(cards))

                return BasicStats(
                    totalCards: totalCards,
                    daysSinceStart: daysSinceStart,
                    thisMonthCards: thisMonthCards,
                    lastMonthDiff: lastMonthDiff,
                    currentStreak: currentStreak
                )
            }
            .asDriver(onErrorDriveWith: .empty())

        let monthlyDataDriver = input.viewWillAppear
            .map { _ -> [MonthlyData] in
                let cards = realm.objects(Card.self)
                return self.calculateMonthlyData(cards: Array(cards))
            }
            .asDriver(onErrorJustReturn: [])

        let weekdayDataDriver = input.viewWillAppear
            .map { _ -> [WeekdayData] in
                let cards = realm.objects(Card.self)
                return self.calculateWeekdayData(cards: Array(cards))
            }
            .asDriver(onErrorJustReturn: [])

        let timeDataDriver = input.viewWillAppear
            .map { _ -> [TimeData] in
                let cards = realm.objects(Card.self)
                return self.calculateTimeData(cards: Array(cards))
            }
            .asDriver(onErrorJustReturn: [])

        let moodDataDriver = input.viewWillAppear
            .map { _ -> [MoodData] in
                let cards = realm.objects(Card.self)
                return self.generateMockMoodData(cardCount: cards.count)
            }
            .asDriver(onErrorJustReturn: [])

        let weekdayInsightDriver = input.viewWillAppear
            .map { _ -> String in
                let cards = Array(realm.objects(Card.self))
                guard !cards.isEmpty else {
                    return NSLocalizedString("stats.no_data_weekday", comment: "")
                }

                let calendar = Calendar.current
                var weekdayDict: [Int: Int] = [:]

                for card in cards {
                    let weekday = calendar.component(.weekday, from: card.createdDate)
                    weekdayDict[weekday, default: 0] += 1
                }

                guard let mostFrequentWeekday = weekdayDict.max(by: { $0.value < $1.value }),
                      mostFrequentWeekday.value > 0 else {
                    return NSLocalizedString("stats.no_data_weekday", comment: "")
                }

                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale.current
                dateFormatter.dateFormat = "EEEE"

                var dateComponents = DateComponents()
                dateComponents.weekday = mostFrequentWeekday.key
                guard let sampleDate = calendar.nextDate(after: Date(), matching: dateComponents, matchingPolicy: .nextTime) else {
                    return NSLocalizedString("stats.no_data_weekday", comment: "")
                }

                let weekdayName = dateFormatter.string(from: sampleDate)
                return String(format: NSLocalizedString("stats.weekday_insight", comment: ""), weekdayName)
            }
            .asDriver(onErrorJustReturn: NSLocalizedString("stats.no_data_weekday", comment: ""))

        let timeInsightDriver = timeDataDriver
            .map { data -> String in
                guard let mostFrequent = data.max(by: { $0.count < $1.count }),
                      mostFrequent.count > 0 else {
                    return NSLocalizedString("stats.no_data_time", comment: "")
                }
                let emoji = self.getTimeEmoji(for: mostFrequent.timeOfDay)
                return emoji + " " + String(format: NSLocalizedString("stats.time_insight", comment: ""), mostFrequent.timeOfDay)
            }

        let thisMonthInsightDriver = basicStatsDriver
            .map { stats -> String in
                return String(format: NSLocalizedString("stats.thismonth_insight", comment: ""), stats.thisMonthCards)
            }

        return Output(
            basicStats: basicStatsDriver,
            monthlyData: monthlyDataDriver,
            weekdayData: weekdayDataDriver,
            timeData: timeDataDriver,
            moodData: moodDataDriver,
            weekdayInsight: weekdayInsightDriver,
            timeInsight: timeInsightDriver,
            thisMonthInsight: thisMonthInsightDriver
        )
    }

    private func calculateDaysSinceStart(cards: [Card]) -> Int {
        guard let firstCard = cards.sorted(by: { $0.createdDate < $1.createdDate }).first else {
            return 0
        }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: firstCard.createdDate, to: Date()).day ?? 0
        return max(0, days)
    }

    private func calculateThisMonthCards(cards: [Card]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        return cards.filter { card in
            calendar.isDate(card.createdDate, equalTo: now, toGranularity: .month)
        }.count
    }

    private func calculateLastMonthDiff(cards: [Card]) -> Int {
        let calendar = Calendar.current
        let now = Date()

        let thisMonth = cards.filter { card in
            calendar.isDate(card.createdDate, equalTo: now, toGranularity: .month)
        }.count

        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) else {
            return 0
        }

        let lastMonthCount = cards.filter { card in
            calendar.isDate(card.createdDate, equalTo: lastMonth, toGranularity: .month)
        }.count

        return thisMonth - lastMonthCount
    }

    private func calculateCurrentStreak(cards: [Card]) -> Int {
        let calendar = Calendar.current
        let sortedCards = cards.sorted { $0.createdDate > $1.createdDate }

        var streak = 0
        var currentDate = Date()

        for _ in 0..<365 {
            let hasCard = sortedCards.contains { card in
                calendar.isDate(card.createdDate, inSameDayAs: currentDate)
            }

            if hasCard {
                streak += 1
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = yesterday
            } else {
                break
            }
        }

        return streak
    }

    private func calculateMonthlyData(cards: [Card]) -> [MonthlyData] {
        let calendar = Calendar.current
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy/MM"

        var monthlyDict: [String: Int] = [:]

        for i in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthString = dateFormatter.string(from: monthDate)
            monthlyDict[monthString] = 0
        }

        for card in cards {
            let monthString = dateFormatter.string(from: card.createdDate)
            if monthlyDict[monthString] != nil {
                monthlyDict[monthString, default: 0] += 1
            }
        }

        var result: [MonthlyData] = []
        for i in (0..<6).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthString = dateFormatter.string(from: monthDate)
            result.append(MonthlyData(month: monthString, count: monthlyDict[monthString] ?? 0))
        }
        return result
    }

    private func calculateWeekdayData(cards: [Card]) -> [WeekdayData] {
        let calendar = Calendar.current
        var weekdayDict: [Int: Int] = [:]

        for card in cards {
            let weekday = calendar.component(.weekday, from: card.createdDate)
            weekdayDict[weekday, default: 0] += 1
        }

        let weekdayNames = [
            NSLocalizedString("weekday.sunday", comment: ""),
            NSLocalizedString("weekday.monday", comment: ""),
            NSLocalizedString("weekday.tuesday", comment: ""),
            NSLocalizedString("weekday.wednesday", comment: ""),
            NSLocalizedString("weekday.thursday", comment: ""),
            NSLocalizedString("weekday.friday", comment: ""),
            NSLocalizedString("weekday.saturday", comment: "")
        ]

        return (1...7).map { weekday in
            WeekdayData(
                weekday: weekdayNames[weekday - 1],
                count: weekdayDict[weekday, default: 0]
            )
        }
    }

    private func calculateTimeData(cards: [Card]) -> [TimeData] {
        let calendar = Calendar.current
        let morningKey = NSLocalizedString("stats.time_morning", comment: "")
        let afternoonKey = NSLocalizedString("stats.time_afternoon", comment: "")
        let eveningKey = NSLocalizedString("stats.time_evening", comment: "")
        let nightKey = NSLocalizedString("stats.time_night", comment: "")

        var timeDict: [String: Int] = [
            morningKey: 0,
            afternoonKey: 0,
            eveningKey: 0,
            nightKey: 0
        ]

        for card in cards {
            let hour = calendar.component(.hour, from: card.createdDate)
            let timeKey: String
            switch hour {
            case 6..<12:
                timeKey = morningKey
            case 12..<18:
                timeKey = afternoonKey
            case 18..<22:
                timeKey = eveningKey
            default:
                timeKey = nightKey
            }
            timeDict[timeKey, default: 0] += 1
        }

        return [
            TimeData(timeOfDay: morningKey, count: timeDict[morningKey] ?? 0),
            TimeData(timeOfDay: afternoonKey, count: timeDict[afternoonKey] ?? 0),
            TimeData(timeOfDay: eveningKey, count: timeDict[eveningKey] ?? 0),
            TimeData(timeOfDay: nightKey, count: timeDict[nightKey] ?? 0)
        ]
    }

    private func generateMockMoodData(cardCount: Int) -> [MoodData] {
        guard cardCount > 0 else { return [] }

        let allMoods: [Mood] = [.happy, .excited, .loved, .peaceful, .grateful, .sad, .angry, .anxious, .tired, .nostalgic]
        let weights = [0.25, 0.20, 0.18, 0.15, 0.12, 0.05, 0.02, 0.01, 0.01, 0.01]

        var moodData: [MoodData] = []
        for (index, mood) in allMoods.enumerated() {
            let count = Int(Double(cardCount) * weights[index])
            if count > 0 {
                moodData.append(MoodData(mood: mood, count: count))
            }
        }

        return Array(moodData.prefix(5))
    }

    private func getTimeEmoji(for timeOfDay: String) -> String {
        let morningKey = NSLocalizedString("stats.time_morning", comment: "")
        let afternoonKey = NSLocalizedString("stats.time_afternoon", comment: "")
        let eveningKey = NSLocalizedString("stats.time_evening", comment: "")
        let nightKey = NSLocalizedString("stats.time_night", comment: "")

        switch timeOfDay {
        case morningKey:
            return "🌅"
        case afternoonKey:
            return "☀️"
        case eveningKey:
            return "🌆"
        case nightKey:
            return "🌙"
        default:
            return "🌙"
        }
    }
}
