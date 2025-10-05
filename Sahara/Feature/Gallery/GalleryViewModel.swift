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

final class GalleryViewModel {
    private let disposeBag = DisposeBag()
    private let realmManager = RealmManager.shared
    
    struct Input {
        let viewWillAppear: Observable<Void>
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
        let photos = BehaviorRelay<[Card]>(value: [])
        let selectedViewType = BehaviorRelay<GalleryViewType>(value: .date)
        
        let calendarItems = Observable
            .combineLatest(currentMonth, photos)
            .map { month, photoMemos in
                self.generateCalendar(for: month, photoMemos: photoMemos)
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

        let isEmptyRelay = BehaviorRelay<Bool>(value: true)

        let checkEmpty: () -> Void = { [weak self] in
            guard let self = self else { return }
            let isEmpty = self.realmManager.isEmpty(Card.self)
            isEmptyRelay.accept(isEmpty)
        }

        input.addButtonTapped
            .bind(to: showPhotoPicker)
            .disposed(by: disposeBag)

        input.viewWillAppear
            .withLatestFrom(currentMonth)
            .bind(with: self) { owner, month in
                owner.reloadCurrentMonthPhotos(month, photos: photos)
                checkEmpty()
            }
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
            .bind(with: self) { owner, month in
                owner.reloadCurrentMonthPhotos(month, photos: photos)
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
            isEmpty: isEmptyRelay.asDriver()
        )
    }
    
    private func reloadCurrentMonthPhotos(_ date: Date, photos: BehaviorRelay<[Card]>) {
        let memos = realmManager.fetchMemos(in: date)
        photos.accept(memos)
    }
    
    private func generateCalendar(for month: Date, photoMemos: [Card]) -> [DayItem] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")

        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = range.count

        var items: [DayItem] = []

        // 이전 달의 날짜들
        for i in (1..<firstWeekday).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: firstDay) {
                items.append(DayItem(date: date, cards: [], isCurrentMonth: false))
            }
        }

        // 현재 달의 날짜들
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day-1, to: firstDay) {
                let memosForDay = photoMemos.filter {
                    calendar.isDate($0.createdDate, inSameDayAs: date)
                }
                items.append(DayItem(date: date, cards: memosForDay, isCurrentMonth: true))
            }
        }

        // 다음 달의 날짜들 (항상 42칸이 되도록)
        let remainingCells = 42 - items.count
        if let lastDay = calendar.date(byAdding: .day, value: daysInMonth - 1, to: firstDay) {
            for i in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    items.append(DayItem(date: date, cards: [], isCurrentMonth: false))
                }
            }
        }

        return items
    }
}
