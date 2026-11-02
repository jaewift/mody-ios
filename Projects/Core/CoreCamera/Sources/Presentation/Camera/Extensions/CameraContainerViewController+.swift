//
//  CameraContainerViewController+.swift
//  CoreCamera
//
//  Created by 김동준 on 7/23/26
//

import CoreCameraInterface
import CoreModyImageInterface
import DesignSystem
import PhotosUI
import UIKit

extension CameraContainerViewController {
    func capturePhoto() {
        let capturedPhotoProcessor = capturedPhotoProcessor

        sessionController.capture { [weak self, capturedPhotoProcessor] data in
            // AVFoundation 콜백 큐에서 파일 저장과 다운샘플링을 끝내고 UI만 main으로 넘깁니다.
            guard let data,
                  let capturedPhoto = try? capturedPhotoProcessor.makeCapturedPhoto(
                    data: data,
                    fileName: PhotoFileNameUtil.makeCameraFileName()
                  ) else {
                return
            }

            DispatchQueue.main.async { [weak self, capturedPhotoProcessor] in
                guard let self else {
                    capturedPhotoProcessor.removeCapturedPhoto(capturedPhoto)
                    return
                }
                self.setCapturedPhoto(capturedPhoto)
            }
        }
    }

    func presentPhotoLibrary() {
        guard presentedViewController == nil else { return }
        cancelPhotoLibraryLoad()

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.presentationController?.delegate = self
        present(picker, animated: true)
    }

    func setCapturedPhoto(_ capturedPhoto: CameraCapturedPhoto) {
        clearCapturedPhoto(removingFile: true)
        resetRotationState()
        previewView.isHidden = true
        self.capturedPhoto = capturedPhoto
        rotatedPreviewImage = capturedPhoto.previewImage
        selectedImageView.image = rotatedPreviewImage
        photoCanvasView.isHidden = false
        rotationControlsView.isHidden = false
        bottomCameraShutterView.isHidden = true
        photoConfirmationContainerView.isHidden = false
        roiOverlayView.isHidden = !isCropEnabled
        // 새 사진은 이전 사진의 회전·확대·위치 값과 무관하게 최초 상태에서 편집을 시작합니다.
        view.layoutIfNeeded()
        updatePhotoEditLayout(reset: true)
        closeButton.tintColor = .systemWhite
        sessionController.stop()
    }

    func resetCapturedPhoto() {
        cancelPhotoLibraryLoad()
        clearCapturedPhoto(removingFile: true)
        resetRotationState()
        rotatedPreviewImage = nil
        photoEditLayout = nil
        previewView.isHidden = false
        photoCanvasView.isHidden = true
        rotationControlsView.isHidden = true
        bottomCameraShutterView.isHidden = false
        photoConfirmationContainerView.isHidden = true
        roiOverlayView.isHidden = true
        closeButton.tintColor = .systemWhite
        sessionController.start()
    }

    func completeCapture() {
        // 회전 중에는 화면과 저장될 방향이 일치하지 않으므로 업로드를 무시합니다.
        guard !isRotatingPhoto else { return }
        cancelPhotoLibraryLoad()

        guard let result = autoreleasepool(invoking: { () -> CameraCaptureResult? in
            guard let capturedPhoto else { return nil }

            let previewImage: UIImage
            let normalizedSelectionFrame: CGRect
            guard let rotatedPreviewImage = self.rotatedPreviewImage else {
                return nil
            }

            if isCropEnabled {
                // 가이드 내부에 보이는 영역 그대로를 최종 이미지로 사용합니다.
                guard let photoEditLayout = self.photoEditLayout,
                      let cropOutput = CameraImageCropper().crop(
                        image: rotatedPreviewImage,
                        selectionFrame: roiOverlayView.selectionFrame,
                        displayedImageFrame: photoEditLayout.displayedImageFrame
                      ) else {
                    return nil
                }
                previewImage = cropOutput.croppedImage
                normalizedSelectionFrame = cropOutput.normalizedSelectionFrame
            } else {
                previewImage = rotatedPreviewImage
                normalizedSelectionFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
            }

            let originalFile: TemporaryImageFile
            if imageRotation == .zero {
                originalFile = capturedPhoto.originalFile
            } else {
                guard let rotatedFile = try? capturedPhotoProcessor.makeRotatedFile(
                    from: capturedPhoto,
                    rotation: imageRotation
                ) else {
                    return nil
                }
                originalFile = rotatedFile
            }

            let result = CameraCaptureResult(
                originalFile: originalFile,
                croppedPreviewImage: previewImage,
                normalizedSelectionFrame: normalizedSelectionFrame
            )
            clearCapturedPhoto(removingFile: false)
            return result
        }) else {
            return
        }

        onComplete(result)
    }

    @objc func closeTapped() {
        cancelPhotoLibraryLoad()
        sessionController.cancelPendingCapture()
        clearCapturedPhoto(removingFile: true)
        resetRotationState()
        onCancel()
    }

    func removeCapturedPhotoFile() {
        guard let capturedPhoto else { return }
        capturedPhotoProcessor.removeCapturedPhoto(capturedPhoto)
    }

    func clearCapturedPhoto(removingFile: Bool) {
        if removingFile {
            removeCapturedPhotoFile()
        }
        capturedPhoto = nil
        selectedImageView.image = nil
    }

    func cancelPhotoLibraryLoad() {
        photoLibraryLoadProgress?.cancel()
        photoLibraryLoadProgress = nil
        photoLibraryLoadID = nil
    }

    /// 상단 버튼과 하단 확인 버튼 사이 영역에 crop 가이드를 고정 배치합니다.
    func updatePhotoGuideFrame() {
        guard isCropEnabled else { return }

        let horizontalInset: CGFloat = 24
        let verticalSpacing: CGFloat = 16
        let minY = topControlsStackView.frame.maxY + verticalSpacing
        let maxY = photoConfirmationContainerView.frame.minY - verticalSpacing
        let availableFrame = CGRect(
            x: horizontalInset,
            y: minY,
            width: max(0, view.bounds.width - (horizontalInset * 2)),
            height: max(0, maxY - minY)
        )
        roiOverlayView.updateSelectionFrame(in: availableFrame)
    }

    /// 화면 크기나 가이드가 바뀌었거나 `reset`이면 최초 배율로 다시 배치하고, 아니면 현재 상태를 유지합니다.
    func updatePhotoEditLayout(reset: Bool = false) {
        // 회전 애니메이션 중에는 transform이 적용되어 있어 frame을 변경하지 않습니다.
        guard !isRotatingPhoto else { return }
        guard let rotatedPreviewImage else {
            photoEditLayout = nil
            return
        }

        let containerBounds = photoCanvasView.bounds
        let guideFrame = isCropEnabled ? roiOverlayView.selectionFrame : .zero
        let needsReset = reset
            || photoEditLayout?.imageSize != rotatedPreviewImage.size
            || photoEditLayout?.containerBounds != containerBounds
            || photoEditLayout?.guideFrame != guideFrame

        if needsReset {
            photoEditLayout = CameraPhotoEditLayout(
                imageSize: rotatedPreviewImage.size,
                containerBounds: containerBounds,
                guideFrame: guideFrame
            )
        }
        applyPhotoEditLayout()
    }

    func applyPhotoEditLayout() {
        guard let photoEditLayout else { return }
        selectedImageView.frame = photoEditLayout.displayedImageFrame
    }

    @objc func handlePhotoPinch(_ recognizer: UIPinchGestureRecognizer) {
        guard recognizer.state == .began || recognizer.state == .changed,
              !isRotatingPhoto,
              var photoEditLayout else { return }

        photoEditLayout.zoom(
            by: recognizer.scale,
            anchor: recognizer.location(in: photoCanvasView)
        )
        recognizer.scale = 1
        self.photoEditLayout = photoEditLayout
        applyPhotoEditLayout()
    }

    @objc func handlePhotoPan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .began || recognizer.state == .changed,
              !isRotatingPhoto,
              var photoEditLayout else { return }

        photoEditLayout.pan(by: recognizer.translation(in: photoCanvasView))
        recognizer.setTranslation(.zero, in: photoCanvasView)
        self.photoEditLayout = photoEditLayout
        applyPhotoEditLayout()
    }

    func rotateCapturedPhoto(clockwiseDegrees: Int) {
        guard let capturedPhoto, !isRotatingPhoto else { return }

        let nextRotation = imageRotation.adding(clockwise: clockwiseDegrees)
        let rotatedImage = CameraImageRotator().rotate(
            capturedPhoto.previewImage,
            by: nextRotation
        )
        let currentFrame = selectedImageView.frame
        guard let targetLayout = CameraPhotoEditLayout(
            imageSize: rotatedImage.size,
            containerBounds: photoCanvasView.bounds,
            guideFrame: isCropEnabled ? roiOverlayView.selectionFrame : .zero
        ), currentFrame.width > 0, currentFrame.height > 0 else { return }

        isRotatingPhoto = true
        imageRotation = nextRotation
        rotationControlsView.isUserInteractionEnabled = false
        // 진행 중인 pinch·pan을 취소해 회전 후 누적된 이동량이 한 번에 반영되지 않도록 합니다.
        setPhotoGesturesEnabled(false)

        // 가이드는 고정한 채 사진만 회전하며, 회전 후 배치될 위치·크기로 정확히 도달하도록 함께 변환합니다.
        let targetFrame = targetLayout.displayedImageFrame
        let isQuarterTurn = !abs(clockwiseDegrees).isMultiple(of: 180)
        let scale = targetFrame.width / (isQuarterTurn ? currentFrame.height : currentFrame.width)
        let radians = CGFloat(clockwiseDegrees) * .pi / 180
        let targetTransform = CGAffineTransform(
            translationX: targetFrame.midX - currentFrame.midX,
            y: targetFrame.midY - currentFrame.midY
        )
        .rotated(by: radians)
        .scaledBy(x: scale, y: scale)

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: { [weak self] in
                self?.selectedImageView.transform = targetTransform
            },
            completion: { [weak self] _ in
                // 애니메이션 도중 다시 찍기·새 사진 선택·닫기가 일어났다면 이전 사진의 회전 결과를 반영하지 않습니다.
                guard let self,
                      self.isRotatingPhoto,
                      self.capturedPhoto?.originalFile.fileURL == capturedPhoto.originalFile.fileURL else {
                    return
                }

                UIView.performWithoutAnimation {
                    self.selectedImageView.transform = .identity
                    self.rotatedPreviewImage = rotatedImage
                    self.selectedImageView.image = rotatedImage
                    self.photoEditLayout = targetLayout
                    self.applyPhotoEditLayout()
                }
                self.isRotatingPhoto = false
                self.rotationControlsView.isUserInteractionEnabled = true
                self.setPhotoGesturesEnabled(true)
            }
        )
    }

    func setPhotoGesturesEnabled(_ isEnabled: Bool) {
        photoPinchGestureRecognizer.isEnabled = isEnabled && isCropEnabled
        photoPanGestureRecognizer.isEnabled = isEnabled && isCropEnabled
    }

    func resetRotationState() {
        imageRotation = .zero
        isRotatingPhoto = false
        rotationControlsView.isUserInteractionEnabled = true
        setPhotoGesturesEnabled(true)
        selectedImageView.transform = .identity
    }
}
