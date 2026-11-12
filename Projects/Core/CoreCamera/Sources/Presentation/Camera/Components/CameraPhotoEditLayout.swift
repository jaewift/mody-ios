//
//  CameraPhotoEditLayout.swift
//  CoreCamera
//

import CoreGraphics

/// 고정된 crop 가이드 뒤에서 사진을 확대·축소·이동할 때의 배율과 위치를 계산합니다.
///
/// - 최초 배율: 원본 비율 그대로 화면에 맞추되(aspect fit), 가이드를 채우지 못하면 가이드를 채우는 배율
/// - 최소 배율: 사진이 가이드를 완전히 채우는 배율
/// - 최대 배율: 최초 배율의 `maximumZoomFactor`배
/// - 위치: 가이드 내부에 빈 공간이 생기지 않는 범위로 제한
struct CameraPhotoEditLayout: Equatable {
    static let maximumZoomFactor: CGFloat = 3

    let imageSize: CGSize
    let containerBounds: CGRect
    let guideFrame: CGRect
    let initialScale: CGFloat
    let minimumScale: CGFloat
    let maximumScale: CGFloat

    private(set) var scale: CGFloat
    private(set) var center: CGPoint

    init?(
        imageSize: CGSize,
        containerBounds: CGRect,
        guideFrame: CGRect
    ) {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerBounds.width > 0,
              containerBounds.height > 0 else { return nil }

        let fitScale = min(
            containerBounds.width / imageSize.width,
            containerBounds.height / imageSize.height
        )
        let hasGuide = !guideFrame.isNull
            && guideFrame.width > 0
            && guideFrame.height > 0
        let fillGuideScale = hasGuide
            ? max(
                guideFrame.width / imageSize.width,
                guideFrame.height / imageSize.height
            )
            : fitScale

        self.imageSize = imageSize
        self.containerBounds = containerBounds
        self.guideFrame = hasGuide ? guideFrame : .zero
        self.minimumScale = fillGuideScale
        self.initialScale = max(fitScale, fillGuideScale)
        self.maximumScale = initialScale * Self.maximumZoomFactor
        self.scale = initialScale
        self.center = CGPoint(x: containerBounds.midX, y: containerBounds.midY)
        self.center = clampedCenter(center, scale: scale)
    }

    var displayedImageFrame: CGRect {
        let size = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        return CGRect(
            x: center.x - (size.width / 2),
            y: center.y - (size.height / 2),
            width: size.width,
            height: size.height
        )
    }

    /// `anchor`(손가락 중심점)를 기준으로 확대·축소합니다.
    mutating func zoom(by factor: CGFloat, anchor: CGPoint) {
        guard factor.isFinite, factor > 0 else { return }

        let nextScale = min(max(scale * factor, minimumScale), maximumScale)
        let appliedFactor = nextScale / scale
        let nextCenter = CGPoint(
            x: anchor.x + ((center.x - anchor.x) * appliedFactor),
            y: anchor.y + ((center.y - anchor.y) * appliedFactor)
        )

        scale = nextScale
        center = clampedCenter(nextCenter, scale: nextScale)
    }

    mutating func pan(by translation: CGPoint) {
        guard translation.x.isFinite, translation.y.isFinite else { return }

        center = clampedCenter(
            CGPoint(x: center.x + translation.x, y: center.y + translation.y),
            scale: scale
        )
    }
}

private extension CameraPhotoEditLayout {
    func clampedCenter(_ center: CGPoint, scale: CGFloat) -> CGPoint {
        guard guideFrame.width > 0, guideFrame.height > 0 else {
            return CGPoint(x: containerBounds.midX, y: containerBounds.midY)
        }

        let halfWidth = imageSize.width * scale / 2
        let halfHeight = imageSize.height * scale / 2

        // 사진의 각 변이 가이드의 같은 변보다 바깥에 있어야 가이드 내부에 빈 공간이 생기지 않습니다.
        return CGPoint(
            x: clamp(
                center.x,
                lower: guideFrame.maxX - halfWidth,
                upper: guideFrame.minX + halfWidth
            ),
            y: clamp(
                center.y,
                lower: guideFrame.maxY - halfHeight,
                upper: guideFrame.minY + halfHeight
            )
        )
    }

    func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return (lower + upper) / 2 }
        return min(max(value, lower), upper)
    }
}
