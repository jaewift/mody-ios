//
//  UIWindow+.swift
//  Mody
//
//  Created by 김동준 on 7/8/26.
//

import DesignSystem
import UIKit

extension UIWindow {
    func addKeyboardDismissTapGestureRecognizer() {
        let gestureName = "Mody.KeyboardDismissTapGesture"

        guard gestureRecognizers?.contains(where: { $0.name == gestureName }) != true else {
            return
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing))
        tapGesture.name = gestureName
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = KeyboardDismissTapGestureDelegate.shared
        addGestureRecognizer(tapGesture)
    }
}

/// 키보드를 유지해야 하는 영역을 탭할 때는 키보드를 내리지 않습니다.
private final class KeyboardDismissTapGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissTapGestureDelegate()

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        !touch.isInKeyboardDismissExcludedView
    }
}
