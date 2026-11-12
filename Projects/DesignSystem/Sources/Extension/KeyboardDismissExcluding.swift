//
//  KeyboardDismissExcluding.swift
//  DesignSystem
//
//  Created by Jaewift on 11/12/26.
//

import UIKit

/// 화면을 탭하면 키보드를 내리는 앱 공통 제스처에서 제외할 뷰입니다.
/// 채팅 입력창처럼 키보드를 유지한 채 버튼을 눌러야 하는 영역에 채택합니다.
public protocol KeyboardDismissExcluding: UIView {}

public extension UITouch {
    /// 터치된 뷰나 그 상위 뷰 중 키보드 내리기에서 제외된 뷰가 있는지 확인합니다.
    var isInKeyboardDismissExcludedView: Bool {
        sequence(first: view, next: { $0?.superview })
            .contains { $0 is KeyboardDismissExcluding }
    }
}
