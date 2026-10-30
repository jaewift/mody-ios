import XCTest
import CoreAnalyticsInterface
@testable import CoreAnalytics

final class CoreAnalyticsTests: XCTestCase {
    func testScreenViewIncludesScreenNameInParameters() {
        let event = GoogleAnalyticsEvent.screenView(
            screenName: "Feed",
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
            screenName: "Feed",
            parameters: ["screen_name": "Other"]
        )

        XCTAssertEqual(event.parameters["screen_name"], "Feed")
    }
}
