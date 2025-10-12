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
            version: "1.3.0",
            date: Date(),
            changes: [
                "검색 결과 두 줄 표시 개선",
                "위치 권한 허용 시 즉시 현재 위치 사용",
                "개발자 이메일 설정 보안 강화",
                "설정 화면 계층 구조 개선"
            ]
        ),
        ReleaseNote(
            version: "1.2.0",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            changes: [
                "검색 기능으로 원하는 카드를 빠르게 찾을 수 있어요",
                "통계 기능으로 나의 기록 습관을 한눈에 확인할 수 있어요",
                "카드 수정 시 메모가 사라지던 문제를 해결했어요",
                "앱이 더욱 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.1.0",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            changes: [
                "카드 잠금 기능이 추가되었어요",
                "위치 정보 수정이 더 쉬워졌어요",
                "앱이 더 안정적으로 작동해요"
            ]
        ),
        ReleaseNote(
            version: "1.0.0",
            date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            changes: []
        )
    ]
}
