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
    private var barGradient: DesignToken.Gradient = .warm
    private var useNumericFont = false
    private let yTickCount = 5
    private let leftPadding: CGFloat = 26
    private let rightPadding: CGFloat = 20

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlassCardStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBarGradient(_ gradient: DesignToken.Gradient) {
        self.barGradient = gradient
    }

    func setUseNumericFont(_ value: Bool) {
        self.useNumericFont = value
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
        let maxInt = max(Int(ceil(maxValue)), 1)
        let yAxisStep = max(1, Int(ceil(Double(maxInt) / Double(yTickCount - 1))))
        let adjustedMax = CGFloat(yAxisStep * (yTickCount - 1))
        let barWidth = (bounds.width - leftPadding - rightPadding) / CGFloat(values.count)
        let chartHeight = bounds.height - 60

        for (index, value) in values.enumerated() {
            let barHeight = value > 0 ? max((value / adjustedMax) * chartHeight, 4) : 0
            let x = leftPadding + CGFloat(index) * barWidth + barWidth * 0.1
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

        let maxValue = max(values.max() ?? 1, 1)
        let chartHeight = rect.height - 60
        let barWidth = (rect.width - leftPadding - rightPadding) / CGFloat(values.count)

        let maxInt = max(Int(ceil(maxValue)), 1)
        let yAxisStep = max(1, Int(ceil(Double(maxInt) / Double(yTickCount - 1))))
        let adjustedMaxValue = CGFloat(yAxisStep * (yTickCount - 1))

        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: DesignToken.Typography.small.numericFont,
            .foregroundColor: UIColor.token(.textSecondary)
        ]

        var currentValue = 0
        while currentValue <= Int(adjustedMaxValue) {
            let normalizedY = CGFloat(currentValue) / adjustedMaxValue
            let y = rect.height - 40 - (chartHeight * normalizedY)

            let valueText = "\(currentValue)" as NSString
            let textSize = valueText.size(withAttributes: labelAttributes)
            valueText.draw(at: CGPoint(x: 14, y: y - textSize.height / 2), withAttributes: labelAttributes)

            currentValue += yAxisStep
        }

        // X축 라벨 표시
        for (index, label) in labels.enumerated() {
            guard index < values.count else { break }

            let x = leftPadding + CGFloat(index) * barWidth + barWidth * 0.1
            let width = barWidth * 0.8

            let labelText = label as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: useNumericFont ? DesignToken.Typography.small.numericFont : DesignToken.Typography.small.font,
                .foregroundColor: UIColor.token(.textSecondary)
            ]
            let labelSize = labelText.size(withAttributes: attributes)
            let labelX = x + (width - labelSize.width) / 2
            let labelY = rect.height - 28
            labelText.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: attributes)
        }
    }
}