//
//  IllustratedPopupView.swift
//  Splash
//

import DesignSystem
import SwiftUI
import UIKit

/// 상단 일러스트, 가운데 정렬 제목/본문, 하단 버튼으로 구성된 스플래시 팝업입니다.
/// 공지 팝업과 업데이트 팝업이 같은 레이아웃을 공유합니다.
struct IllustratedPopupView: View {
    static let illustrationSize: CGFloat = 80

    private let image: UIImage?
    private let title: String
    private let contents: String
    private let buttonTitle: String
    private let isButtonEnabled: Bool
    private let action: () -> Void

    init(
        image: UIImage?,
        title: String,
        contents: String,
        buttonTitle: String,
        isButtonEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.contents = contents
        self.buttonTitle = buttonTitle
        self.isButtonEnabled = isButtonEnabled
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            contentsView
            buttonView
        }
        .background(Color.systemWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .hPadding(36)
    }
}

private extension IllustratedPopupView {
    var contentsView: some View {
        VStack(spacing: 0) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Self.illustrationSize,
                        height: Self.illustrationSize
                    )
                    .accessibilityHidden(true)
                    .padding(.bottom, 20)
            }

            MText(
                title,
                style: .b3,
                color: .gray10,
                lineLimit: nil
            )
            .greedyWidth()
            .padding(.bottom, 8)

            MText(
                contents,
                style: .c2,
                color: .gray6,
                lineLimit: nil
            )
            .greedyWidth()
        }
        .padding(.horizontal, 18)
        .padding(.top, 48)
        .padding(.bottom, 28)
    }

    var buttonView: some View {
        MButton(
            buttonTitle,
            style: isButtonEnabled ? .primary : .gray,
            isDisabled: !isButtonEnabled,
            horizontalPadding: 0,
            verticalPadding: 10,
            maxWidth: .infinity,
            action: action
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }
}
