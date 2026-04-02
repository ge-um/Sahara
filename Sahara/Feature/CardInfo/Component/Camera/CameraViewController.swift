//
//  CameraViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import AVFoundation
import SnapKit
import UIKit

final class CameraViewController: UIViewController {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?

    private let captureButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.systemGray5.cgColor
        return button
    }()

    private let flipCameraButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = DesignToken.Overlay.dimOverlay
        button.layer.cornerRadius = 25
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = DesignToken.Overlay.dimOverlay
        button.layer.cornerRadius = 20
        return button
    }()

    private lazy var currentCamera: AVCaptureDevice.Position = defaultCameraPosition

    private var defaultCameraPosition: AVCaptureDevice.Position {
        #if targetEnvironment(macCatalyst)
        return .front
        #else
        return .back
        #endif
    }

    var onPhotoCaptured: ((ImageSourceData) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo

        guard let captureSession = captureSession else { return }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera) else {
            showCameraUnavailableAlert()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }

            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.bounds

            if let previewLayer = previewLayer {
                view.layer.insertSublayer(previewLayer, at: 0)
            }
        } catch {
            showCameraUnavailableAlert()
        }
    }

    private func showCameraUnavailableAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("camera.unavailable_title", comment: ""),
            message: NSLocalizedString("camera.unavailable_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.ok", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func configureUI() {
        view.backgroundColor = .black

        view.addSubview(captureButton)
        view.addSubview(flipCameraButton)
        view.addSubview(cancelButton)

        captureButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-30)
            make.width.height.equalTo(70)
        }

        flipCameraButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(30)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(50)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(30)
            make.centerY.equalTo(captureButton)
            make.width.height.equalTo(40)
        }

        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        if discoverySession.devices.count <= 1 {
            flipCameraButton.isHidden = true
        }
    }

    private func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput?.capturePhoto(with: settings, delegate: self)
    }

    @objc private func flipCamera() {
        guard let captureSession = captureSession else { return }

        captureSession.beginConfiguration()

        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }

        currentCamera = currentCamera == .back ? .front : .back

        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera) else {
            captureSession.commitConfiguration()
            return
        }

        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        } catch {
            currentCamera = currentCamera == .back ? .front : .back
            if let fallbackCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
               let fallbackInput = try? AVCaptureDeviceInput(device: fallbackCamera),
               captureSession.canAddInput(fallbackInput) {
                captureSession.addInput(fallbackInput)
            }
        }

        captureSession.commitConfiguration()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }

        let format = ImageFormatConverter.detect(from: imageData)
        let imageSource = ImageSourceData(
            image: image,
            originalData: imageData,
            format: format
        )

        dismiss(animated: true) { [weak self] in
            self?.onPhotoCaptured?(imageSource)
        }
    }
}
