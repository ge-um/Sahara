//
//  GalleryViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class GalleryViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let realmManager: RealmManagerProtocol

    init(realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
    }

    struct Input {
        let addButtonTapped: Observable<Void>
        let previousMonthTapped: Observable<Void>
        let nextMonthTapped: Observable<Void>
        let viewTypeSelected: Observable<GalleryViewType>
    }
    
    struct Output {
        let showPhotoPicker: Driver<Void>
        let calendarItems: Driver<[DayItem]>
        let currentMonthTitle: Driver<String>
        let selectedViewType: Driver<GalleryViewType>
        let showCalendar: Driver<Bool>
        let isEmpty: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let showPhotoPicker = PublishRelay<Void>()
        let currentMonth = BehaviorRelay(value: Date())
        let selectedViewType = BehaviorRelay<GalleryViewType>(value: .date)

        let photos = currentMonth
            .flatMapLatest { [weak self] month -> Observable<(Date, [CardCalendarItemDTO])> in
                guard let self = self else { return .just((month, [])) }
                return self.realmManager.observeCards(for: .month(month))
                    .map { (month, $0) }
            }
            .share(replay: 1, scope: .whileConnected)

        let calendarItems = photos
            .map { month, items in
                self.generateCalendar(for: month, items: items)
            }

        let currentMonthTitle = currentMonth
            .map { date -> String in
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateFormat = NSLocalizedString("gallery.month_format", comment: "")
                return formatter.string(from: date)
            }

        let showCalendar = selectedViewType
            .map { $0 == .date }

        let isEmpty = realmManager.observeIsEmpty(Card.self)
            .share(replay: 1, scope: .whileConnected)

        input.addButtonTapped
            .bind(to: showPhotoPicker)
            .disposed(by: disposeBag)
        
        input.previousMonthTapped
            .withLatestFrom(currentMonth)
            .map { date -> Date in
                Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
            }
            .bind(to: currentMonth)
            .disposed(by: disposeBag)
        
        input.nextMonthTapped
            .withLatestFrom(currentMonth)
            .map { date -> Date in
                Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
            }
            .bind(to: currentMonth)
            .disposed(by: disposeBag)
        
        currentMonth
            .skip(1)
            .bind { month in
                let calendar = Calendar.current
                let year = calendar.component(.year, from: month)
                let monthValue = calendar.component(.month, from: month)
                AnalyticsManager.shared.logCalendarDateRangeViewed(year: year, month: monthValue)
            }
            .disposed(by: disposeBag)
        
        input.viewTypeSelected
            .bind(to: selectedViewType)
            .disposed(by: disposeBag)
        
        return Output(
            showPhotoPicker: showPhotoPicker.asDriver(onErrorJustReturn: ()),
            calendarItems: calendarItems.asDriver(onErrorJustReturn: []),
            currentMonthTitle: currentMonthTitle.asDriver(onErrorJustReturn: ""),
            selectedViewType: selectedViewType.asDriver(),
            showCalendar: showCalendar.asDriver(onErrorJustReturn: true),
            isEmpty: isEmpty.asDriver(onErrorJustReturn: true)
        )
    }

    private func generateCalendar(for month: Date, items: [CardCalendarItemDTO]) -> [DayItem] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = range.count

        var dayItems: [DayItem] = []

        // 이전 달의 날짜들
        for i in (1..<firstWeekday).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: firstDay) {
                dayItems.append(DayItem(date: date, cards: [], isCurrentMonth: false))
            }
        }

        // 현재 달의 날짜들
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day-1, to: firstDay) {
                let cardsForDay = items.filter {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                dayItems.append(DayItem(date: date, cards: cardsForDay, isCurrentMonth: true))
            }
        }

        // 다음 달의 날짜들 (항상 42칸이 되도록)
        let remainingCells = 42 - dayItems.count
        if let lastDay = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDay) {
            for i in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    dayItems.append(DayItem(date: date, cards: [], isCurrentMonth: false))
                }
            }
        }

        return dayItems
    }
}
