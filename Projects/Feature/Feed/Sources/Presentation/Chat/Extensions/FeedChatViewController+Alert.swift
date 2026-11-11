//
//  FeedChatViewController+Alert.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CommonDomain
import DesignSystem
import SwiftUI
import UIKit

extension FeedChatViewController {
    func configureLoadingView() {
        let loadingView = MLoadingIndicatorView()
            .greedyFrame()
            .background(Color.systemBlack.opacity(0.6))
        let hostingController = UIHostingController(rootView: AnyView(loadingView))

        hostingController.view.backgroundColor = .clear
        hostingController.view.isHidden = true
        loadingHostingController = hostingController

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        hostingController.didMove(toParent: self)
    }

    func setLoadingVisible(_ isVisible: Bool) {
        loadingHostingController?.view.isHidden = !isVisible

        if isVisible,
           let loadingView = loadingHostingController?.view {
            view.bringSubviewToFront(loadingView)
        }
    }

    func setAlert(_ alert: FeedChatReactor.Alert?) {
        dismissAlert()
        guard let alert else { return }

        view.endEditing(true)
        alertHostingController = addHostedView(makeAlertView(alert), to: view)
    }
}

private extension FeedChatViewController {
    func makeAlertView(_ alert: FeedChatReactor.Alert) -> MAlertView {
        let confirm: () -> Void = { [weak self] in
            self?.reactor?.action.onNext(.didConfirmAlert)
        }
        let dismiss: () -> Void = { [weak self] in
            self?.reactor?.action.onNext(.didDismissAlert)
        }

        switch alert {
        case .deleteConfirmation:
            return MAlertView(
                title: "게시물을 삭제하시겠어요?",
                contents: "한 번 삭제한 게시물은 복구할 수 없어요.",
                leadingButton: MAlertButton("취소", style: .gray, action: dismiss),
                trailingButton: MAlertButton("삭제", action: confirm),
                dismissOnBackgroundTap: false,
                onDismiss: dismiss
            )
        case .reportConfirmation:
            return MAlertView(
                title: "게시물을 신고하시겠어요?",
                contents: "신고한 게시물은 검토 후 삭제 처리할 예정입니다.",
                leadingButton: MAlertButton("취소", style: .gray, action: dismiss),
                trailingButton: MAlertButton("신고하기", action: confirm),
                dismissOnBackgroundTap: false,
                onDismiss: dismiss
            )
        case .reportSucceeded:
            return MAlertView(
                title: "신고가 완료되었어요",
                contents: "검토 및 처리는 최대 7일까지 걸릴 수 있어요.",
                trailingButton: MAlertButton("확인", action: dismiss),
                onDismiss: dismiss
            )
        case let .failure(error):
            let title: String
            let contents: String
            if case let .serverError(_, _, fallback) = error {
                title = fallback.title
                contents = fallback.message
            } else {
                title = error.title
                contents = error.message
            }

            return MAlertView(
                title: title,
                contents: contents,
                trailingButton: MAlertButton("확인", action: dismiss),
                onDismiss: dismiss
            )
        }
    }

    func dismissAlert() {
        guard let alertHostingController else { return }

        alertHostingController.willMove(toParent: nil)
        alertHostingController.view.removeFromSuperview()
        alertHostingController.removeFromParent()
        self.alertHostingController = nil
    }
}
