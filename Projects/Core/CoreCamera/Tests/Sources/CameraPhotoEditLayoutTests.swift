//
//  CameraPhotoEditLayoutTests.swift
//  CoreCameraTests
//

import UIKit
import XCTest
@testable import CoreCamera

final class CameraPhotoEditLayoutTests: XCTestCase {
    private let containerBounds = CGRect(x: 0, y: 0, width: 400, height: 800)

    func testInitialLayoutKeepsAspectFitWhenItAlreadyFillsGuide() throws {
        // 세로 3:4 사진은 aspect fit만으로도 가로 전체 · 높이 200 가이드를 채웁니다.
        let layout = try XCTUnwrap(
            CameraPhotoEditLayout(
                imageSize: CGSize(width: 300, height: 400),
                containerBounds: containerBounds,
                guideFrame: CGRect(x: 24, y: 300, width: 352, height: 200)
            )
        )

        XCTAssertEqual(layout.initialScale, 400.0 / 300.0, accuracy: 0.0001)
        XCTAssertEqual(layout.maximumScale, layout.initialScale * 3, accuracy: 0.0001)
        XCTAssertEqual(layout.displayedImageFrame.midX, 200, accuracy: 0.0001)
        XCTAssertEqual(layout.displayedImageFrame.midY, 400, accuracy: 0.0001)
        assertCovers(layout)
    }

    func testInitialLayoutScalesUpToFillGuideWhenAspectFitLeavesEmptySpace() throws {
        // 가로로 긴 사진은 aspect fit 시 높이가 100이라 352x352 가이드를 채우지 못합니다.
        let guideFrame = CGRect(x: 24, y: 224, width: 352, height: 352)
        let layout = try XCTUnwrap(
            CameraPhotoEditLayout(
                imageSize: CGSize(width: 400, height: 100),
                containerBounds: containerBounds,
                guideFrame: guideFrame
            )
        )

        XCTAssertEqual(layout.minimumScale, 352.0 / 100.0, accuracy: 0.0001)
        XCTAssertEqual(layout.initialScale, layout.minimumScale, accuracy: 0.0001)
        assertCovers(layout)
    }

    func testZoomIsClampedBetweenMinimumAndMaximumScale() throws {
        var layout = try XCTUnwrap(
            CameraPhotoEditLayout(
                imageSize: CGSize(width: 300, height: 400),
                containerBounds: containerBounds,
                guideFrame: CGRect(x: 24, y: 224, width: 352, height: 352)
            )
        )

        layout.zoom(by: 10, anchor: CGPoint(x: 200, y: 400))
        XCTAssertEqual(layout.scale, layout.maximumScale, accuracy: 0.0001)
        assertCovers(layout)

        layout.zoom(by: 0.01, anchor: CGPoint(x: 50, y: 50))
        XCTAssertEqual(layout.scale, layout.minimumScale, accuracy: 0.0001)
        assertCovers(layout)
    }

    func testZoomKeepsAnchorPointStationary() throws {
        var layout = try XCTUnwrap(
            CameraPhotoEditLayout(
                imageSize: CGSize(width: 300, height: 400),
                containerBounds: containerBounds,
                guideFrame: CGRect(x: 24, y: 300, width: 352, height: 200)
            )
        )
        let anchor = CGPoint(x: 250, y: 420)
        let before = layout.displayedImageFrame
        let anchorRatioX = (anchor.x - before.minX) / before.width
        let anchorRatioY = (anchor.y - before.minY) / before.height

        layout.zoom(by: 2, anchor: anchor)

        let after = layout.displayedImageFrame
        XCTAssertEqual(after.minX + after.width * anchorRatioX, anchor.x, accuracy: 0.0001)
        XCTAssertEqual(after.minY + after.height * anchorRatioY, anchor.y, accuracy: 0.0001)
    }

    func testPanIsLimitedSoGuideNeverShowsEmptySpace() throws {
        let guideFrame = CGRect(x: 24, y: 300, width: 352, height: 200)
        var layout = try XCTUnwrap(
            CameraPhotoEditLayout(
                imageSize: CGSize(width: 300, height: 400),
                containerBounds: containerBounds,
                guideFrame: guideFrame
            )
        )

        layout.pan(by: CGPoint(x: 10_000, y: 10_000))
        XCTAssertEqual(layout.displayedImageFrame.minX, guideFrame.minX, accuracy: 0.0001)
        XCTAssertEqual(layout.displayedImageFrame.minY, guideFrame.minY, accuracy: 0.0001)

        layout.pan(by: CGPoint(x: -20_000, y: -20_000))
        XCTAssertEqual(layout.displayedImageFrame.maxX, guideFrame.maxX, accuracy: 0.0001)
        XCTAssertEqual(layout.displayedImageFrame.maxY, guideFrame.maxY, accuracy: 0.0001)
    }

    func testCropUsesDisplayedImageFrameAfterZoomAndPan() throws {
        let image = makeImage(size: CGSize(width: 200, height: 200))
        // 화면에서 2배로 확대되어 (−100, −100)부터 그려진 사진의 (0,0)~(200,200) 영역을 자릅니다.
        let cropOutput = try XCTUnwrap(
            CameraImageCropper().crop(
                image: image,
                selectionFrame: CGRect(x: 0, y: 0, width: 200, height: 200),
                displayedImageFrame: CGRect(x: -100, y: -100, width: 400, height: 400)
            )
        )

        XCTAssertEqual(cropOutput.croppedImage.size, CGSize(width: 100, height: 100))
        XCTAssertEqual(cropOutput.normalizedSelectionFrame.minX, 0.25, accuracy: 0.0001)
        XCTAssertEqual(cropOutput.normalizedSelectionFrame.minY, 0.25, accuracy: 0.0001)
        XCTAssertEqual(cropOutput.normalizedSelectionFrame.width, 0.5, accuracy: 0.0001)
        XCTAssertEqual(cropOutput.normalizedSelectionFrame.height, 0.5, accuracy: 0.0001)
    }
}

private extension CameraPhotoEditLayoutTests {
    func assertCovers(
        _ layout: CameraPhotoEditLayout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let frame = layout.displayedImageFrame
        let guide = layout.guideFrame
        let tolerance: CGFloat = 0.0001
        XCTAssertLessThanOrEqual(frame.minX, guide.minX + tolerance, file: file, line: line)
        XCTAssertLessThanOrEqual(frame.minY, guide.minY + tolerance, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.maxX, guide.maxX - tolerance, file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.maxY, guide.maxY - tolerance, file: file, line: line)
    }

    func makeImage(size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
