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
    static let textContentsMaxHeight: CGFloat = 380

    private let info: NoticePopupInfo
    private let image: UIImage?
    private let action: () -> Void
    @State private var contentsHeight: CGFloat = 0

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
        if info.isIllustrated {
            IllustratedPopupView(
                image: image,
                title: info.title ?? "",
                contents: info.contents ?? "",
                buttonTitle: "확인",
                isButtonEnabled: isConfirmationEnabled,
                action: action
            )
        } else {
            textPopup
        }
    }
}

private extension NoticePopupView {
    var textPopup: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                MText(
                    info.title ?? "-",
                    style: .b2,
                    color: .gray10,
                    lineLimit: nil
                )
                .greedyWidth()

                // 짧은 본문은 내용 높이만큼만 차지하고, 최대 높이를 넘을 때만 스크롤합니다.
                ScrollView {
                    contentsText
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { height in
                            contentsHeight = height
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(height: min(contentsHeight, Self.textContentsMaxHeight))
            }
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 20)

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
        .background(Color.systemWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .hPadding(36)
    }

    var contentsText: some View {
        MText(
            info.contents ?? "-",
            style: .c2,
            color: .gray9,
            lineLimit: nil,
            alignment: .leading
        )
        .greedyWidth(.leading)
    }

    var isConfirmationEnabled: Bool {
        info.skipPossible ?? false
    }
}
