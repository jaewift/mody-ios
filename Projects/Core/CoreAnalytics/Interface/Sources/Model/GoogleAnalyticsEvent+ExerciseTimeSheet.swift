//
//  GoogleAnalyticsEvent+ExerciseTimeSheet.swift
//  CoreAnalyticsInterface
//
//  Created by Jaewift on 11/12/26.
//

/// 온보딩과 마이페이지가 함께 쓰는 '모두 같은 시간으로 설정' 시간 선택창 이벤트입니다.
/// 요일별 설정으로 연 선택창은 수집하지 않습니다.
public extension GoogleAnalyticsEvent {
    enum ExerciseTimeSheetEntrySource: String {
        case onboarding
        case mypage
    }

    static func sameTimeClicked(
        selectedDayCount: Int,
        entrySource: ExerciseTimeSheetEntrySource
    ) -> GoogleAnalyticsEvent {
        exerciseTimeSheetEvent(
            name: "same_time_click",
            selectedDayCount: selectedDayCount,
            entrySource: entrySource
        )
    }

    /// 시간을 적용하지 않고 선택창을 닫았을 때
    static func exerciseTimeSheetClosed(
        selectedDayCount: Int,
        entrySource: ExerciseTimeSheetEntrySource
    ) -> GoogleAnalyticsEvent {
        exerciseTimeSheetEvent(
            name: "exercise_time_sheet_close",
            selectedDayCount: selectedDayCount,
            entrySource: entrySource
        )
    }

    /// 선택한 모든 요일에 시간을 적용했을 때. 마이페이지의 최종 저장과는 별개입니다.
    static func exerciseTimeSheetApplied(
        selectedDayCount: Int,
        entrySource: ExerciseTimeSheetEntrySource
    ) -> GoogleAnalyticsEvent {
        exerciseTimeSheetEvent(
            name: "exercise_time_sheet_apply",
            selectedDayCount: selectedDayCount,
            entrySource: entrySource
        )
    }
}

private extension GoogleAnalyticsEvent {
    static func exerciseTimeSheetEvent(
        name: String,
        selectedDayCount: Int,
        entrySource: ExerciseTimeSheetEntrySource
    ) -> GoogleAnalyticsEvent {
        GoogleAnalyticsEvent(
            name: name,
            parameters: [
                "selected_day_count": String(selectedDayCount),
                "entry_source": entrySource.rawValue
            ]
        )
    }
}
