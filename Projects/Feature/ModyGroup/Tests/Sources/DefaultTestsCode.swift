import ComposableArchitecture
import CommonDomain
import CoreAnalyticsInterface
import Foundation
import ModyGroupInterface
import XCTest
@testable import ModyGroup

@MainActor
final class ModyGroupTests: XCTestCase {
    func testGroupJoinScreenViewIncludesEntrySource() async {
        let analyticsUseCase = ModyGroupAnalyticsUseCaseSpy()
        let store = makeParticipateStore(entrySource: .relaunch, analyticsUseCase: analyticsUseCase)

        await store.send(.onAppear)
        await store.finish()

        XCTAssertEqual(
            analyticsUseCase.googleAnalyticsEvents,
            [GoogleAnalyticsEvent(name: "screen_view", parameters: ["screen_name": "GroupJoin", "entry_source": "relaunch"])]
        )
    }

    func testCreateButtonTapLogsGroupCreateClickWithEntrySource() async {
        let analyticsUseCase = ModyGroupAnalyticsUseCaseSpy()
        let store = makeParticipateStore(entrySource: .signup, analyticsUseCase: analyticsUseCase)

        await store.send(.createButtonTapped)
        await store.finish()

        XCTAssertEqual(
            analyticsUseCase.googleAnalyticsEvents,
            [GoogleAnalyticsEvent(name: "group_create_click", parameters: ["entry_source": "signup"])]
        )
    }

    func testJoinGroupSuccessLogsJoinGroupWithEntrySource() async {
        let analyticsUseCase = ModyGroupAnalyticsUseCaseSpy()
        let store = makeParticipateStore(entrySource: .feed, analyticsUseCase: analyticsUseCase)

        await store.send(.joinGroupSuccessfully)
        await store.finish()

        XCTAssertEqual(
            analyticsUseCase.googleAnalyticsEvents,
            [GoogleAnalyticsEvent(name: "join_group", parameters: ["entry_source": "feed"])]
        )
    }

    func testJoinGroupFailureMapsServerCodeToFailReason() async {
        let cases: [(NetworkError, String)] = [
            (.serverError(code: "GROUP301", message: nil, fallback: .unknown), "invalid_code"),
            (.serverError(code: "GROUP304", message: nil, fallback: .unknown), "group_full"),
            (.serverError(code: "COMMON500", message: nil, fallback: .unknown), "error"),
            (.unknown, "error")
        ]

        for (error, expectedReason) in cases {
            let analyticsUseCase = ModyGroupAnalyticsUseCaseSpy()
            let store = makeParticipateStore(entrySource: .feed, analyticsUseCase: analyticsUseCase)

            await store.send(.joinGroupFailure(error, code: ""))
            await store.finish()

            XCTAssertEqual(
                analyticsUseCase.googleAnalyticsEvents,
                [GoogleAnalyticsEvent(name: "group_join_fail", parameters: ["fail_reason": expectedReason, "entry_source": "feed"])],
                "\(error)"
            )
        }
    }

        func testCreateGroupSuccessLogsGroupCreateSuccessWithEntrySource() async {
        let analyticsUseCase = ModyGroupAnalyticsUseCaseSpy()
        let store = TestStore(initialState: GroupCreateFeature.State(entrySource: .rejoin)) {
            GroupCreateFeature(
                groupUseCase: ModyGroupUseCaseMock(),
                analyticsUseCase: analyticsUseCase
            )
        }
        store.exhaustivity = .off

        await store.send(.createGroupSuccessfully(code: "ABCDEFGH", groupName: "모디"))
        await store.finish()

        XCTAssertEqual(
            analyticsUseCase.googleAnalyticsEvents,
            [GoogleAnalyticsEvent(name: "group_create_success", parameters: ["entry_source": "rejoin"])]
        )
    }

    func testRootPassesEntrySourceToChildScreens() {
        let state = ModyGroupRootFeature.State(
            entryPoint: .main,
            entrySource: .feed,
            showSignUpDoneContents: false,
            initialScreen: .create(needBackButton: true)
        )

        XCTAssertEqual(state.groupParticipateState.entrySource, .feed)
        XCTAssertEqual(state.groupCreateState.entrySource, .feed)
    }
}

private extension ModyGroupTests {
    func makeParticipateStore(
        entrySource: ModyGroupEntrySource,
        analyticsUseCase: ModyGroupAnalyticsUseCaseSpy
    ) -> TestStoreOf<GroupParticipateFeature> {
        let store = TestStore(
            initialState: GroupParticipateFeature.State(
                entrySource: entrySource,
                showSignUpDoneContents: false,
                showsBackButton: false
            )
        ) {
            GroupParticipateFeature(
                groupUseCase: ModyGroupUseCaseMock(),
                analyticsUseCase: analyticsUseCase
            )
        }
        store.exhaustivity = .off
        return store
    }
}

private final class ModyGroupAnalyticsUseCaseSpy: AnalyticsUseCaseProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var events: [GoogleAnalyticsEvent] = []

    var googleAnalyticsEvents: [GoogleAnalyticsEvent] {
        lock.withLock { events }
    }

    func setUserID(_ userID: String) {}
    func setUserNickname(_ nickname: String) {}
    func reset() {}
    func log(_ event: AmplitudeLogEvent) {}
    func viewDidLoad(screenName: String) {}

    func log(_ event: GoogleAnalyticsEvent) {
        lock.withLock { events.append(event) }
    }
}

private struct ModyGroupUseCaseMock: GroupUseCaseProtocol {
    func createGroup(name: String) async throws -> String { "ABCDEFGH" }
    func joinGroup(code: String) async throws {}
    func getGroups() async throws -> [GroupModel] { [] }
    func exitGroup(groupId: Int) async throws {}
}
