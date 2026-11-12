//
//  ROIOverlayView.swift
//  CoreCamera
//
//  Created by 김동준 on 7/20/26.
//

import DesignSystem
import UIKit

/// 화면에 고정된 crop 가이드입니다. 사용자는 가이드가 아니라 뒤의 사진을 움직이므로 터치를 받지 않습니다.
final class ROIOverlayView: UIView {
    private let defaultSelectionHeight: CGFloat = 200
    private let borderWidth: CGFloat = 4
    private let selectionAspectRatio: CGSize?

    private(set) var selectionFrame = CGRect.zero

    private let dimLayer = CAShapeLayer()
    private let borderLayer = CAShapeLayer()

    init(selectionAspectRatio: CGSize?) {
        self.selectionAspectRatio = selectionAspectRatio
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }

    /// `availableFrame` 안에서 지정된 비율로 가장 큰 가이드를 중앙에 배치합니다.
    /// 비율이 없으면 가로 전체 · 높이 200pt 가이드를 사용합니다.
    func updateSelectionFrame(in availableFrame: CGRect) {
        let aspectRatio = selectionAspectRatio ?? CGSize(
            width: availableFrame.width,
            height: min(defaultSelectionHeight, availableFrame.height)
        )
        selectionFrame = ROISelectionFrameCalculator.maximumFrame(
            aspectRatio: aspectRatio,
            in: availableFrame
        )
        updateLayers()
    }
}

private extension ROIOverlayView {
    func setupUI() {
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false

        dimLayer.fillColor = UIColor.black.withAlphaComponent(0.35).cgColor
        dimLayer.fillRule = .evenOdd
        layer.addSublayer(dimLayer)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.main.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.lineDashPattern = [8, 8]
        layer.addSublayer(borderLayer)
    }

    func updateLayers() {
        let dimPath = UIBezierPath(rect: bounds)
        dimPath.append(UIBezierPath(rect: selectionFrame))
        dimLayer.frame = bounds
        dimLayer.path = dimPath.cgPath

        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(rect: selectionFrame).cgPath
    }
}
