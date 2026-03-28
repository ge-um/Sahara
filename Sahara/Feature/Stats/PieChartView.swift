//
//  PieChartView.swift
//  Sahara
//
//  Created by 금가경 on 10/11/25.
//

import UIKit

final class PieChartView: UIView {
    private var labels: [String] = []
    private var values: [CGFloat] = []
    private var sliceLayers: [CAGradientLayer] = []
    private var labelLayers: [CATextLayer] = []

    private let moodGradients: [String: [UIColor]] = [
        "Happy": [UIColor(hex: "#FFF59D"), UIColor(hex: "#FFA726")],
        "Excited": [UIColor(hex: "#FFB74D"), UIColor(hex: "#E64A19")],
        "Loved": [UIColor(hex: "#F48FB1"), UIColor(hex: "#E91E63")],
        "Peaceful": [UIColor(hex: "#81D4FA"), UIColor(hex: "#1976D2")],
        "Grateful": [UIColor(hex: "#FFCC80"), UIColor(hex: "#F57C00")],
        "Sad": [UIColor(hex: "#CFD8DC"), UIColor(hex: "#607D8B")],
        "Angry": [UIColor(hex: "#EF9A9A"), UIColor(hex: "#C62828")],
        "Anxious": [UIColor(hex: "#CE93D8"), UIColor(hex: "#8E24AA")],
        "Tired": [UIColor(hex: "#B2DFDB"), UIColor(hex: "#00897B")],
        "Nostalgic": [UIColor(hex: "#FFE082"), UIColor(hex: "#F57F17")]
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .token(.backgroundGlass)
        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(labels: [String], values: [CGFloat]) {
        self.labels = labels
        self.values = values
        sliceLayers.forEach { $0.removeFromSuperlayer() }
        sliceLayers.removeAll()
        labelLayers.forEach { $0.removeFromSuperlayer() }
        labelLayers.removeAll()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sliceLayers.forEach { $0.removeFromSuperlayer() }
        sliceLayers.removeAll()
        labelLayers.forEach { $0.removeFromSuperlayer() }
        labelLayers.removeAll()

        drawPieChart()
    }

    private func drawPieChart() {
        guard !values.isEmpty, bounds.width > 0, bounds.height > 0 else { return }

        let total = values.reduce(0, +)
        guard total > 0 else { return }

        let centerX = bounds.width / 2
        let centerY = bounds.height / 2 - 20
        let radius: CGFloat = min(bounds.width, bounds.height - 80) / 2 - 20

        var startAngle: CGFloat = -.pi / 2

        for (index, value) in values.enumerated() {
            let percent = value / total
            let endAngle = startAngle + (percent * 2 * .pi)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: centerX, y: centerY))
            path.addArc(
                withCenter: CGPoint(x: centerX, y: centerY),
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.close()

            let gradientColors = moodGradients[labels[index]] ?? [UIColor(hex: "#FFB3BA"), UIColor(hex: "#FFDFBA")]
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bounds
            gradientLayer.colors = gradientColors.map { $0.cgColor }
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

            let maskLayer = CAShapeLayer()
            maskLayer.path = path.cgPath
            gradientLayer.mask = maskLayer

            layer.addSublayer(gradientLayer)
            sliceLayers.append(gradientLayer)

            let labelAngle = startAngle + (endAngle - startAngle) / 2
            let labelRadius = radius + 30
            let labelX = centerX + cos(labelAngle) * labelRadius
            let labelY = centerY + sin(labelAngle) * labelRadius

            let labelText = "\(labels[index])\n\(Int(percent * 100))%"
            let textLayer = CATextLayer()
            textLayer.string = labelText
            textLayer.font = FontSystem.galmuriMono(size: 12)
            textLayer.fontSize = 12
            textLayer.foregroundColor = UIColor.token(.textPrimary).cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = window?.screen.scale ?? 2.0

            let textSize = (labelText as NSString).size(withAttributes: [.font: FontSystem.galmuriMono(size: 12)])
            textLayer.frame = CGRect(
                x: labelX - textSize.width / 2,
                y: labelY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )

            layer.addSublayer(textLayer)
            labelLayers.append(textLayer)

            startAngle = endAngle
        }
    }
}
