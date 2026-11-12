//
//  FeedRecordCardContentView.swift
//  Feed
//
//  Created by Jaewift on 11/11/26.
//

import CoreModyImageInterface
import DesignSystem
import SnapKit
import UIKit

/// 기록 사진 위에 시간·메뉴(운동) 정보를 겹쳐 보여주는 카드입니다.
/// 피드 목록과 채팅 화면 상단 슬라이드에서 함께 사용합니다.
final class FeedRecordCardContentView: UIView {
    private let recordImageView = FeedRecordCardImageView()
    private let infoStackView = UIStackView()
    private let firstTitleLabel = MUILabel(style: .c2, color: .gray1, alignment: .left)
    private let firstValueLabel = MUILabel(style: .b1, color: .systemWhite, alignment: .left)
    private let secondTitleLabel = MUILabel(style: .c2, color: .gray1, alignment: .left)
    private let secondValueLabel = MUILabel(style: .b2, color: .systemWhite, alignment: .left)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func prepareForReuse() {
        recordImageView.prepareForReuse()
    }

    func configure(
        _ viewState: FeedRecordCardContentViewState,
        imageLoader: RemoteImageLoading
    ) {
        recordImageView.configureRecord(
            urlString: viewState.imageUrl,
            cropRegion: viewState.imageCropRegion,
            cornerRadius: 16,
            imageLoader: imageLoader
        )
        firstTitleLabel.text = viewState.firstInfoTitle
        firstValueLabel.text = viewState.firstInfoValue
        secondTitleLabel.text = viewState.secondInfoTitle
        secondValueLabel.text = viewState.secondInfoValue
    }
}

private extension FeedRecordCardContentView {
    func setupUI() {
        layer.cornerRadius = 16
        clipsToBounds = true

        infoStackView.axis = .vertical
        infoStackView.spacing = 8
    }

    func setupLayout() {
        addSubview(recordImageView)
        addSubview(infoStackView)

        infoStackView.addArrangedSubview(
            makeInfoStack(titleLabel: firstTitleLabel, valueLabel: firstValueLabel)
        )
        infoStackView.addArrangedSubview(
            makeInfoStack(titleLabel: secondTitleLabel, valueLabel: secondValueLabel)
        )

        recordImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        infoStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.lessThanOrEqualToSuperview().offset(-20)
            $0.bottom.equalToSuperview().offset(-16)
        }
    }

    func makeInfoStack(titleLabel: UILabel, valueLabel: UILabel) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .leading
        return stackView
    }
}
