//
//  UIView+Gradient.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import RxSwift
import SnapKit

private final class SolidColorBackgroundView: UIView {}

private final class PhotoBackgroundView: UIView {
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(image: UIImage) {
        imageView.image = image
    }
}

private final class GradientBackgroundView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    func configure(_ gradient: DesignToken.Gradient) {
        let gl = layer as! CAGradientLayer
        gl.colors = gradient.colors
        gl.locations = gradient.locations
        gl.startPoint = gradient.startPoint
        gl.endPoint = gradient.endPoint
    }

    func configure(colors: [CGColor]) {
        let gl = layer as! CAGradientLayer
        gl.colors = colors
        gl.locations = [0.0, 1.0]
        gl.startPoint = CGPoint(x: 0.5, y: 0)
        gl.endPoint = CGPoint(x: 0.5, y: 1)
    }
}

private final class DotPatternBackgroundView: UIView {
    func configure(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        let tileSize = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let patternImage = renderer.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        }
        backgroundColor = UIColor(patternImage: patternImage)
    }
}

extension UIView {
    func applyGradient(_ gradient: DesignToken.Gradient, removeExisting: Bool = false) {
        if let existing = subviews.first(where: { $0 is GradientBackgroundView }) as? GradientBackgroundView {
            existing.configure(gradient)
            return
        }

        let bgView = GradientBackgroundView()
        bgView.configure(gradient)
        bgView.isUserInteractionEnabled = false
        insertSubview(bgView, at: 0)
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func applyDotPattern(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        if subviews.contains(where: { $0 is DotPatternBackgroundView }) { return }

        let bgView = DotPatternBackgroundView()
        bgView.configure(dotSize: dotSize, spacing: spacing, color: color)
        bgView.isUserInteractionEnabled = false
        insertSubview(bgView, at: 1)
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func applyGradientWithDots(_ gradient: DesignToken.Gradient, dotSize: CGFloat, spacing: CGFloat, dotColor: UIColor) {
        applyGradient(gradient)
        applyDotPattern(dotSize: dotSize, spacing: spacing, color: dotColor)
    }

    func applyBackgroundConfig(_ config: BackgroundConfig, photoData: Data? = nil) {
        removeAllBackgroundViews()

        switch config.theme {
        case .solidColor(let hex):
            let bgView = SolidColorBackgroundView()
            bgView.backgroundColor = UIColor(hex: hex)
            bgView.isUserInteractionEnabled = false
            insertSubview(bgView, at: 0)
            bgView.snp.makeConstraints { $0.edges.equalToSuperview() }

        case .gradient(let gradientId):
            if let gradient = DesignToken.Gradient(rawValue: gradientId) {
                applyGradient(gradient)
            }

        case .customGradient(let startHex, let endHex):
            let bgView = GradientBackgroundView()
            bgView.configure(colors: [UIColor(hex: startHex).cgColor, UIColor(hex: endHex).cgColor])
            bgView.isUserInteractionEnabled = false
            insertSubview(bgView, at: 0)
            bgView.snp.makeConstraints { $0.edges.equalToSuperview() }

        case .photo(let fileName):
            if let data = photoData ?? BackgroundThemeService.shared.loadBackgroundPhoto(fileName: fileName),
               let image = UIImage(data: data) {
                let bgView = PhotoBackgroundView()
                bgView.configure(image: image)
                bgView.isUserInteractionEnabled = false
                insertSubview(bgView, at: 0)
                bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
            }
        }

        if config.isDotPatternEnabled {
            applyDotPattern(dotSize: 5, spacing: 32, color: .token(.textOnAccent))
        }
    }

    func bindBackgroundTheme(disposedBy disposeBag: DisposeBag) {
        BackgroundThemeService.shared.currentConfig
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] config in
                self?.applyBackgroundConfig(config)
            })
            .disposed(by: disposeBag)
    }

    func removeAllBackgroundViews() {
        subviews.forEach { view in
            if view is GradientBackgroundView
                || view is DotPatternBackgroundView
                || view is SolidColorBackgroundView
                || view is PhotoBackgroundView {
                view.removeFromSuperview()
            }
        }
    }
}
