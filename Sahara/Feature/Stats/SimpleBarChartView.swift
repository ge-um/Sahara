//
//  SimpleBarChartView.swift
//  Sahara
//
//  Created by 금가경 on 10/11/25.
//

import UIKit

final class SimpleBarChartView: UIView {
    private var labels: [String] = []
    private var values: [CGFloat] = []
    private var gradientLayers: [CAGradientLayer] = []
    private var barGradient: ColorSystem.Gradient = .cardInfoBackground

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hex: "#D2D1E4").withAlphaComponent(0.2)
        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBarGradient(_ gradient: ColorSystem.Gradient) {
        self.barGradient = gradient
    }

    func configure(labels: [String], values: [CGFloat]) {
        self.labels = labels
        self.values = values

        gradientLayers.forEach { $0.removeFromSuperlayer() }
        gradientLayers.removeAll()

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayers.forEach { $0.removeFromSuperlayer() }
        gradientLayers.removeAll()

        guard !values.isEmpty, bounds.width > 0, bounds.height > 0 else { return }

        let maxValue = max(values.max() ?? 1, 1)
        let barWidth = (bounds.width - 40) / CGFloat(values.count)
        let chartHeight = bounds.height - 60

        for (index, value) in values.enumerated() {
            let barHeight = value > 0 ? max((value / maxValue) * chartHeight, 4) : 0
            let x = 20 + CGFloat(index) * barWidth + barWidth * 0.1
            let y = bounds.height - 40 - barHeight
            let width = barWidth * 0.8

            if barHeight > 0 {
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = CGRect(x: x, y: y, width: width, height: barHeight)
                gradientLayer.colors = barGradient.colors
                gradientLayer.locations = barGradient.locations
                gradientLayer.startPoint = barGradient.startPoint
                gradientLayer.endPoint = barGradient.endPoint
                gradientLayer.cornerRadius = 4
                layer.addSublayer(gradientLayer)
                gradientLayers.append(gradientLayer)
            }
        }

        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard !values.isEmpty, !labels.isEmpty else { return }

        let barWidth = (rect.width - 40) / CGFloat(values.count)

        for (index, label) in labels.enumerated() {
            guard index < values.count else { break }

            let x = 20 + CGFloat(index) * barWidth + barWidth * 0.1
            let width = barWidth * 0.8

            let labelText = label as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: FontSystem.galmuriMono(size: 11),
                .foregroundColor: UIColor.black
            ]
            let labelSize = labelText.size(withAttributes: attributes)
            let labelX = x + (width - labelSize.width) / 2
            let labelY = rect.height - 28
            labelText.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: attributes)
        }
    }
}