//
//  ReleaseNote.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import Foundation

struct ReleaseNote {
    let version: String
    let date: Date
    let changes: [String]

    var dateString: String {
        return date.relativeOrAbsoluteString()
    }

    static let allVersions: [ReleaseNote] = [
        ReleaseNote(
            version: "1.4.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 17).date!,
            changes: [
                "그리기 모드에서 실행 취소/다시 실행 기능을 사용할 수 있어요",
                "폴더별로 카드를 정리할 수 있어요",
                "중국어를 지원해요",
                "매주 작성한 카드를 요약해주는 주간 리포트 알림을 받을 수 있어요",
                "사진 속 텍스트를 인식해서 검색할 수 있어요",
                "카드 편집 시 사진과 스티커를 더 자유롭게 확대하고 축소할 수 있어요",
                "통계에서 카드 작성 패턴을 확인할 수 있어요",
                "통계 차트에 Y축이 추가되어 더 보기 쉬워졌어요",
                "앱이 더욱 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.3.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 13).date!,
            changes: [
                "설정 탭이 추가되어 앱을 더 편리하게 관리할 수 있어요",
                "개발자에게 문의하기 기능으로 의견을 쉽게 전달할 수 있어요",
                "버전 기록에서 업데이트 내용을 확인할 수 있어요",
                "카드 보기 화면에서 긴 이미지가 스크롤되지 않던 문제를 해결했어요",
                "앱이 더욱 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.2.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 10).date!,
            changes: [
                "검색 기능으로 원하는 카드를 빠르게 찾을 수 있어요",
                "통계 기능으로 나의 기록 습관을 한눈에 확인할 수 있어요",
                "카드 수정 시 메모가 사라지던 문제를 해결했어요",
                "앱이 더욱 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.1.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 6).date!,
            changes: [
                "카드 잠금 기능이 추가되었어요",
                "위치 정보 수정이 더 쉬워졌어요",
                "앱이 더 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.0.0",
            date: DateComponents(calendar: .current, year: 2025, month: 10, day: 6).date!,
            changes: []
        )
    ]
}
