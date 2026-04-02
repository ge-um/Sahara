//
//  SyncProgressView.swift
//  Sahara
//

import RxSwift
import SnapKit
import UIKit

final class SyncProgressView: UIView {

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = DesignToken.Overlay.toastBackground
        view.layer.cornerRadius = 16
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        return imageView
    }()

    private let spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()

    private var dismissWork: DispatchWorkItem?
    private let statusSubject = PublishSubject<CloudSyncStatus>()
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        bindStatus()
        observeNotifications()
        isHidden = true
        checkInitialStatus()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        isUserInteractionEnabled = false

        addSubview(containerView)
        containerView.addSubview(spinner)
        containerView.addSubview(iconView)
        containerView.addSubview(statusLabel)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(16)
            make.centerX.equalToSuperview()
        }

        spinner.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(spinner.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSyncStatusChanged(_:)),
            name: .cloudSyncStatusChanged,
            object: nil
        )
    }

    @objc private func handleSyncStatusChanged(_ notification: Notification) {
        guard let status = CloudSyncService.current?.status else { return }
        statusSubject.onNext(status)
    }

    private func checkInitialStatus() {
        guard let status = CloudSyncService.current?.status else { return }
        switch status {
        case .syncing, .upToDate, .error:
            statusSubject.onNext(status)
        case .disabled, .accountUnavailable:
            break
        }
    }

    private func bindStatus() {
        statusSubject
            .distinctUntilChanged()
            .flatMapLatest { status -> Observable<CloudSyncStatus> in
                switch status {
                case .upToDate:
                    return Observable.just(status)
                        .delay(.milliseconds(300), scheduler: MainScheduler.instance)
                default:
                    return Observable.just(status)
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                self?.applyStatus(status)
            })
            .disposed(by: disposeBag)
    }

    private func applyStatus(_ status: CloudSyncStatus) {
        dismissWork?.cancel()
        dismissWork = nil

        switch status {
        case .syncing:
            spinner.startAnimating()
            iconView.isHidden = true
            statusLabel.text = NSLocalizedString("sync.status_syncing", comment: "")
            slideIn()

        case .upToDate:
            spinner.stopAnimating()
            iconView.isHidden = false
            iconView.image = UIImage(systemName: "checkmark.icloud")
            statusLabel.text = NSLocalizedString("sync.status_up_to_date", comment: "")
            slideIn()
            scheduleDismiss(delay: 1.5)

        case .error:
            spinner.stopAnimating()
            iconView.isHidden = false
            iconView.image = UIImage(systemName: "exclamationmark.icloud")
            statusLabel.text = NSLocalizedString("sync.status_error", comment: "")
            slideIn()
            scheduleDismiss(delay: 2.0)

        case .disabled, .accountUnavailable:
            slideOut()
        }
    }

    private func slideIn() {
        guard isHidden || containerView.transform.ty < 0 else { return }

        isHidden = false
        containerView.transform = CGAffineTransform(translationX: 0, y: -40)
        containerView.alpha = 0

        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }

    private func slideOut() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -40)
            self.containerView.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.containerView.transform = .identity
        }
    }

    private func scheduleDismiss(delay: TimeInterval) {
        let work = DispatchWorkItem { [weak self] in
            self?.slideOut()
        }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
