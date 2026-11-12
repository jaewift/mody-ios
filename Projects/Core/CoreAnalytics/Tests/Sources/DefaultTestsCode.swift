import XCTest
import CoreAnalyticsInterface
@testable import CoreAnalytics

final class CoreAnalyticsTests: XCTestCase {
    func testScreenViewIncludesScreenNameInParameters() {
        let event = GoogleAnalyticsEvent.screenView(
            .feed,
            parameters: ["group_count": "2"]
        )

        XCTAssertEqual(event.name, "screen_view")
        XCTAssertEqual(
            event.parameters,
            ["screen_name": "Feed", "group_count": "2"]
        )
    }

    func testScreenViewScreenNameOverridesParameter() {
        let event = GoogleAnalyticsEvent.screenView(
            .feed,
            parameters: ["screen_name": "Other"]
        )

        XCTAssertEqual(event.parameters["screen_name"], "Feed")
    }

    func testScreenNamesMatchSpec() {
        XCTAssertEqual(
            GoogleAnalyticsScreen.allCases.map(\.rawValue),
            [
                "Login", "Terms", "TermsDetail", "Nickname", "Birth", "Weight",
                "Alarm", "Permission", "GroupJoin", "GroupCreate", "CodeShare",
                "Feed", "Challenge", "ChallengeChange", "WeeklyChallenge"
            ]
        )
    }
}
