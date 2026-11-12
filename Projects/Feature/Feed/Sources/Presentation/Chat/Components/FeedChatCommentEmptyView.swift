//
//  FeedChatCommentEmptyView.swift
//  Feed
//
//  Created by Jaewift on 11/12/26.
//

import DesignSystem
import SwiftUI

/// 피드에 댓글이 하나도 없을 때 댓글 목록 자리에 보여주는 안내 화면입니다.
struct FeedChatCommentEmptyView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image.imgModyCommentEmpty
                .resizable()
                .scaledToFit()
                .frame(width: 45, height: 57)

            MText(
                "아직 응원 댓글이 없어요",
                style: .b3,
                color: .gray10
            )
            .padding(.top, 24)

            MText(
                "첫 응원 한마디를 남겨보세요!",
                style: .b7,
                color: .gray6
            )
            .padding(.top, 4)
        }
        .padding(.top, 90)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
