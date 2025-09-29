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
        // TODO: - Realm 데이터 바뀔 때로 refactoring
        let viewWillAppear: Observable<Void>
        let addButtonTapped: Observable<Void>
    }
    
    struct Output {
        let showPhotoPicker: Driver<Void>
        let calendarItems: Driver<[DayItem]>
    }
    
    func transform(input: Input) -> Output {
        let showPhotoPicker = PublishRelay<Void>()
        let photos = BehaviorRelay<[PhotoMemo]>(value: [])
        let currentMonth = BehaviorRelay(value: Date())
        
        let calendarItems = photos
            .map { photoMemos in
                self.generateCalendar(for: Date(), photoMemos: photoMemos)
            }
        
        
        input.addButtonTapped
            .bind(to: showPhotoPicker)
            .disposed(by: disposeBag)
        
        input.viewWillAppear
            .bind(with: self) { owner, _ in
                owner.reloadCurrentMonthPhotos(currentMonth.value, photos: photos)
            }
            .disposed(by: disposeBag)
        
        return Output(
            showPhotoPicker: showPhotoPicker.asDriver(onErrorJustReturn: ()),
            calendarItems: calendarItems.asDriver(onErrorJustReturn: []),
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
