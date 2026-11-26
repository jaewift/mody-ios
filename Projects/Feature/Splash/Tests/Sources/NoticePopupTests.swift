import CommonDomain
import XCTest
@testable import Splash

final class NoticePopupTests: XCTestCase {
    // MARK: - NoticePopupInfo

    func testDecodesNoticeWithNewFields() throws {
        let json = """
        {
          "id": "chat_release_1_2_1",
          "imageURL": "https://example.com/notice.png",
          "title": "채팅 신규 기능 출시",
          "contents": "피드를 눌러보세요!",
          "skipPossible": true
        }
        """

        let notice = try JSONDecoder().decode(NoticePopupInfo.self, from: Data(json.utf8))

        XCTAssertEqual(notice.id, "chat_release_1_2_1")
        XCTAssertEqual(notice.validImageURL?.absoluteString, "https://example.com/notice.png")
        XCTAssertTrue(notice.isIllustrated)
        XCTAssertEqual(notice.oneTimeID, "chat_release_1_2_1")
    }

    func testDecodesLegacyNoticeWithoutNewFields() throws {
        let json = #"{"title": "점검 안내", "contents": "점검 중입니다.", "skipPossible": false}"#

        let notice = try JSONDecoder().decode(NoticePopupInfo.self, from: Data(json.utf8))

        XCTAssertNil(notice.id)
        XCTAssertNil(notice.validImageURL)
        XCTAssertFalse(notice.isIllustrated)
        XCTAssertNil(notice.oneTimeID)
    }

    func testOneTimeIDIsNilWhenNoticeCannotBeSkipped() {
        let notice = NoticePopupInfo(id: "maintenance", title: "점검", skipPossible: false)

        XCTAssertNil(notice.oneTimeID)
    }

    func testOneTimeIDIsNilWhenIDIsBlank() {
        let notice = NoticePopupInfo(id: "  ", title: "공지", skipPossible: true)

        XCTAssertNil(notice.oneTimeID)
    }

    func testValidImageURLRejectsNonHTTPSURL() {
        let cases = ["http://example.com/a.png", "ftp://example.com/a.png", "not a url", ""]

        for urlString in cases {
            let notice = NoticePopupInfo(imageURL: urlString, title: "공지")
            XCTAssertNil(notice.validImageURL, "Expected \(urlString) to be rejected")
        }
    }

    func testValidImageURLTrimsWhitespace() {
        let notice = NoticePopupInfo(imageURL: " https://example.com/a.png\n", title: "공지")

        XCTAssertEqual(notice.validImageURL?.absoluteString, "https://example.com/a.png")
    }

    // MARK: - SplashUseCase

    func testGetNoticeToShowReturnsNilForEmptyNotice() {
        let useCase = makeUseCase(notice: NoticePopupInfo())

        XCTAssertNil(useCase.getNoticeToShow())
    }

    func testGetNoticeToShowReturnsUnseenOneTimeNotice() {
        let notice = makeOneTimeNotice()
        let useCase = makeUseCase(notice: notice)

        XCTAssertEqual(useCase.getNoticeToShow(), notice)
    }

    func testGetNoticeToShowSkipsSeenOneTimeNotice() {
        let notice = makeOneTimeNotice()
        let repository = NoticeRepositoryStub(notice: notice, seenNoticeIDs: [notice.id ?? ""])
        let useCase = SplashUseCase(splashRepository: repository)

        XCTAssertNil(useCase.getNoticeToShow())
    }

    func testGetNoticeToShowAlwaysReturnsUnskippableNotice() {
        let notice = NoticePopupInfo(id: "maintenance", title: "점검", skipPossible: false)
        let repository = NoticeRepositoryStub(notice: notice, seenNoticeIDs: ["maintenance"])
        let useCase = SplashUseCase(splashRepository: repository)

        XCTAssertEqual(useCase.getNoticeToShow(), notice)
    }

    func testGetNoticeToShowAlwaysReturnsNoticeWithoutID() {
        let notice = NoticePopupInfo(title: "공지", skipPossible: true)
        let useCase = makeUseCase(notice: notice)

        XCTAssertEqual(useCase.getNoticeToShow(), notice)
    }

    func testMarkNoticeAsSeenHidesNoticeOnNextLaunch() {
        let notice = makeOneTimeNotice()
        let repository = NoticeRepositoryStub(notice: notice)
        let useCase = SplashUseCase(splashRepository: repository)

        useCase.markNoticeAsSeen(notice)

        XCTAssertEqual(repository.seenNoticeIDs, ["chat_release_1_2_1"])
        XCTAssertNil(useCase.getNoticeToShow())
    }

    func testMarkNoticeAsSeenIgnoresNoticeWithoutOneTimeID() {
        let notice = NoticePopupInfo(id: "maintenance", title: "점검", skipPossible: false)
        let repository = NoticeRepositoryStub(notice: notice)
        let useCase = SplashUseCase(splashRepository: repository)

        useCase.markNoticeAsSeen(notice)

        XCTAssertTrue(repository.seenNoticeIDs.isEmpty)
    }

    // MARK: - Update popup image

    func testGetUpdatePopupImageURLReturnsValidURL() {
        let repository = NoticeRepositoryStub(
            notice: nil,
            remoteConfigStrings: [.updatePopupImageURL: " https://example.com/update.png "]
        )
        let useCase = SplashUseCase(splashRepository: repository)

        XCTAssertEqual(useCase.getUpdatePopupImageURL()?.absoluteString, "https://example.com/update.png")
    }

    func testGetUpdatePopupImageURLReturnsNilForEmptyOrInvalidValue() {
        for value in ["", "   ", "http://example.com/update.png", "not a url"] {
            let repository = NoticeRepositoryStub(
                notice: nil,
                remoteConfigStrings: [.updatePopupImageURL: value]
            )
            let useCase = SplashUseCase(splashRepository: repository)

            XCTAssertNil(useCase.getUpdatePopupImageURL(), "Expected \(value) to be rejected")
        }
    }

    // MARK: - Helpers

    private func makeOneTimeNotice() -> NoticePopupInfo {
        NoticePopupInfo(
            id: "chat_release_1_2_1",
            imageURL: "https://example.com/notice.png",
            title: "채팅 신규 기능 출시",
            contents: "피드를 눌러보세요!",
            skipPossible: true
        )
    }

    private func makeUseCase(notice: NoticePopupInfo?) -> SplashUseCase {
        SplashUseCase(splashRepository: NoticeRepositoryStub(notice: notice))
    }
}

private final class NoticeRepositoryStub: SplashRepositoryProtocol {
    private let notice: NoticePopupInfo?
    private let remoteConfigStrings: [RemoteConfigKeys: String]
    private(set) var seenNoticeIDs: [String]

    init(
        notice: NoticePopupInfo?,
        seenNoticeIDs: [String] = [],
        remoteConfigStrings: [RemoteConfigKeys: String] = [:]
    ) {
        self.notice = notice
        self.seenNoticeIDs = seenNoticeIDs
        self.remoteConfigStrings = remoteConfigStrings
    }

    func getHealthCheck() async throws -> Bool { true }
    func fetchAndActivate() async {}
    func getRemoteConfigBool(for key: RemoteConfigKeys) -> Bool { false }
    func getRemoteConfigString(for key: RemoteConfigKeys) -> String { remoteConfigStrings[key] ?? "" }
    func getNoticePopupInfo() -> NoticePopupInfo? { notice }
    func hasSeenNotice(id: String) -> Bool { seenNoticeIDs.contains(id) }
    func markNoticeAsSeen(id: String) { seenNoticeIDs = seenNoticeIDs + [id] }
    func getStoredAuthSession() -> AuthSession? { nil }
}
