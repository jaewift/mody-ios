//
//  NoticePopupView.swift
//  Splash
//

import DesignSystem
import SwiftUI
import UIKit

/// Remote Config 공지 팝업입니다.
/// `imageURL`이 있는 공지는 일러스트형(가운데 정렬), 없는 공지는 텍스트형(점검 공지 등)으로 그립니다.
struct NoticePopupView: View {
    static let illustrationSize: CGFloat = 80
    static let textContentsMaxHeight: CGFloat = 380

    private let info: NoticePopupInfo
    private let image: UIImage?
    private let action: () -> Void

    init(
        info: NoticePopupInfo,
        image: UIImage?,
        action: @escaping () -> Void
    ) {
        self.info = info
        self.image = image
        self.action = action
    }

    var body: some View {
        VStack(spacing: 0) {
            if info.isIllustrated {
                illustratedContents
            } else {
                textContents
            }

            confirmButton
        }
        .background(Color.systemWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .hPadding(36)
    }
}

private extension NoticePopupView {
    var illustratedContents: some View {
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
                info.title ?? "",
                style: .b3,
                color: .gray10,
                lineLimit: nil
            )
            .greedyWidth()
            .padding(.bottom, 8)

            MText(
                info.contents ?? "",
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

    var textContents: some View {
        VStack(spacing: 12) {
            MText(
                info.title ?? "-",
                style: .b2,
                color: .gray10,
                lineLimit: nil
            )
            .greedyWidth()

            ScrollView {
                MText(
                    info.contents ?? "-",
                    style: .c2,
                    color: .gray9,
                    lineLimit: nil,
                    alignment: .leading
                )
                .greedyWidth(.leading)
            }
            .frame(maxHeight: Self.textContentsMaxHeight)
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
        .padding(.bottom, 20)
    }

    var confirmButton: some View {
        MButton(
            "확인",
            style: isConfirmationEnabled ? .primary : .gray,
            isDisabled: !isConfirmationEnabled,
            horizontalPadding: 0,
            verticalPadding: 10,
            maxWidth: .infinity,
            action: action
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    var isConfirmationEnabled: Bool {
        info.skipPossible ?? false
    }
}
