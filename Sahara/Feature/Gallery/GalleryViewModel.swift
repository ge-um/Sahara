//
//  GalleryViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

//import Foundation
//import RealmSwift
//import RxCocoa
//import RxSwift
//
//final class GalleryViewModel {
//    private let disposeBag = DisposeBag()
//    private let realm = try! Realm()
//    
//    struct Input {
//        let viewWillAppear: Observable<Void>
//        let addButtonTapped: Observable<Void>
//        let previousMonthTapped: Observable<Void>
//        let nextMonthTapped: Observable<Void>
//    }
//    
//    struct Output {
//        let showPhotoPicker: Driver<Void>
//        let calendarItems: Driver<[DayItem]>
//        let currentMonthTitle: Driver<String>
//    }
//    
//    func transform(input: Input) -> Output {
//        let showPhotoPicker = PublishRelay<Void>()
//        let currentMonth = BehaviorRelay(value: Date())
//        let photos = BehaviorRelay<[PhotoMemo]>(value: [])
//        
//        let calendarItems = Observable
//            .combineLatest(currentMonth, photos)
//            .map { month, photoMemos in
//                self.generateCalendar(for: month, photoMemos: photoMemos)
//            }
//        
//        let currentMonthTitle = currentMonth
//            .map { date -> String in
//                let formatter = DateFormatter()
//                formatter.locale = Locale(identifier: "ko_KR")
//                formatter.dateFormat = "yyyy년 MM월"
//                return formatter.string(from: date)
//            }
//        
//        input.addButtonTapped
//            .bind(to: showPhotoPicker)
//            .disposed(by: disposeBag)
//        
//        input.viewWillAppear
//            .withLatestFrom(currentMonth)
//            .bind(with: self) { owner, month in
//                owner.reloadCurrentMonthPhotos(month, photos: photos)
//            }
//            .disposed(by: disposeBag)
//        
//        input.previousMonthTapped
//            .withLatestFrom(currentMonth)
//            .map { date -> Date in
//                Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
//            }
//            .bind(to: currentMonth)
//            .disposed(by: disposeBag)
//        
//        input.nextMonthTapped
//            .withLatestFrom(currentMonth)
//            .map { date -> Date in
//                Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
//            }
//            .bind(to: currentMonth)
//            .disposed(by: disposeBag)
//        
//        currentMonth
//            .skip(1)
//            .bind(with: self) { owner, month in
//                owner.reloadCurrentMonthPhotos(month, photos: photos)
//            }
//            .disposed(by: disposeBag)
//        
//        return Output(
//            showPhotoPicker: showPhotoPicker.asDriver(onErrorJustReturn: ()),
//            calendarItems: calendarItems.asDriver(onErrorJustReturn: []),
//            currentMonthTitle: currentMonthTitle.asDriver(onErrorJustReturn: "")
//        )
//    }
//    
//    private func reloadCurrentMonthPhotos(_ date: Date, photos: BehaviorRelay<[PhotoMemo]>) {
//        let calendar = Calendar.current
//        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
//              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return }
//        
//        let results = realm.objects(PhotoMemo.self)
//            .filter("date >= %@ AND date <= %@", startOfMonth, endOfMonth)
//            .sorted(byKeyPath: "date", ascending: true)
//        
//        photos.accept(Array(results))
//    }
//    
//    private func generateCalendar(for month: Date, photoMemos: [PhotoMemo]) -> [DayItem] {
//        var calendar = Calendar.current
//        calendar.locale = Locale(identifier: "ko_KR")
//        
//        guard let range = calendar.range(of: .day, in: .month, for: month),
//              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
//            return []
//        }
//        
//        let firstWeekday = calendar.component(.weekday, from: firstDay)
//        
//        var items: [DayItem] = []
//        
//        for _ in 1..<firstWeekday {
//            items.append(DayItem(date: nil, photoMemos: []))
//        }
//        
//        for day in range {
//            if let date = calendar.date(byAdding: .day, value: day-1, to: firstDay) {
//                let memosForDay = photoMemos.filter {
//                    calendar.isDate($0.date, inSameDayAs: date)
//                }
//                items.append(DayItem(date: date, photoMemos: memosForDay))
//            }
//        }
//        return items
//    }
//}

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
    private let realm = try! Realm()
    
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
    }
    
    func transform(input: Input) -> Output {
        let showPhotoPicker = PublishRelay<Void>()
        let currentMonth = BehaviorRelay(value: Date())
        let photos = BehaviorRelay<[PhotoMemo]>(value: [])
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
        
        input.addButtonTapped
            .bind(to: showPhotoPicker)
            .disposed(by: disposeBag)
        
        input.viewWillAppear
            .withLatestFrom(currentMonth)
            .bind(with: self) { owner, month in
                owner.reloadCurrentMonthPhotos(month, photos: photos)
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
        )
    }
    
    private func reloadCurrentMonthPhotos(_ date: Date, photos: BehaviorRelay<[PhotoMemo]>) {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { return }

        let results = realm.objects(PhotoMemo.self)
            .filter("date >= %@ AND date <= %@", startOfMonth, endOfMonth)
            .sorted(byKeyPath: "date", ascending: true)

        photos.accept(Array(results))
    }
    
    private func generateCalendar(for month: Date, photoMemos: [PhotoMemo]) -> [DayItem] {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        
        var items: [DayItem] = []
        
        for _ in 1..<firstWeekday {
            items.append(DayItem(date: nil, photoMemos: []))
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day-1, to: firstDay) {
                let memosForDay = photoMemos.filter {
                    calendar.isDate($0.date, inSameDayAs: date)
                }
                items.append(DayItem(date: date, photoMemos: memosForDay))
            }
        }
        return items
    }
}
