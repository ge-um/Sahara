//
//  StatsViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class StatsViewController: UIViewController {
    private let viewModel = StatsViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        return stackView
    }()

    private let basicStatsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private let streakView = StatCardView()
    private let totalCardView = StatCardView()
    private let thisMonthView = StatCardView()

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.monthly_chart", comment: "")
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = .black
        return label
    }()

    private let monthlyChartView = SimpleBarChartView()

    private let weekdayTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.weekday_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = .black
        return label
    }()

    private let weekdayChartView = SimpleBarChartView()

    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.time_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = .black
        return label
    }()

    private let timeChartView = SimpleBarChartView()

    private let moodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.mood_distribution", comment: "")
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = .black
        return label
    }()

    private let moodChartView = PieChartView()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureUI()
        setupCustomNavigationBar()
        bind()
    }

    private func setupCustomNavigationBar() {
        customNavigationBar.configure(title: NSLocalizedString("stats.title", comment: ""))
        customNavigationBar.hideLeftButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func configureUI() {
        view.applyGradientWithDots(.pinkBlue, dotSize: 5, spacing: 32, dotColor: .white)

        timeChartView.setBarGradient(.saveShareButton)
        weekdayChartView.setBarGradient(.saveShareButton)
        monthlyChartView.setBarGradient(.saveShareButton)

        view.addSubview(customNavigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(basicStatsStackView)
        contentStackView.addArrangedSubview(timeTitleLabel)
        contentStackView.addArrangedSubview(timeChartView)
        contentStackView.addArrangedSubview(weekdayTitleLabel)
        contentStackView.addArrangedSubview(weekdayChartView)
        contentStackView.addArrangedSubview(sectionTitleLabel)
        contentStackView.addArrangedSubview(monthlyChartView)
        contentStackView.addArrangedSubview(moodTitleLabel)
        contentStackView.addArrangedSubview(moodChartView)

        basicStatsStackView.addArrangedSubview(streakView)
        basicStatsStackView.addArrangedSubview(totalCardView)
        basicStatsStackView.addArrangedSubview(thisMonthView)

        customNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(54)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(90)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
            make.width.equalTo(scrollView.snp.width).offset(-40)
        }

        basicStatsStackView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }

        monthlyChartView.snp.makeConstraints { make in
            make.height.equalTo(200)
        }

        weekdayChartView.snp.makeConstraints { make in
            make.height.equalTo(180)
        }

        timeChartView.snp.makeConstraints { make in
            make.height.equalTo(180)
        }

        moodChartView.snp.makeConstraints { make in
            make.height.equalTo(250)
        }
    }

    private func bind() {
        let input = StatsViewModel.Input(viewWillAppear: viewWillAppearRelay.asObservable())
        let output = viewModel.transform(input: input)

        output.basicStats
            .drive(with: self) { owner, stats in
                owner.streakView.configure(
                    title: NSLocalizedString("stats.current_streak", comment: ""),
                    value: "\(stats.currentStreak)",
                    unit: NSLocalizedString("stats.days_unit", comment: "")
                )

                owner.totalCardView.configure(
                    title: NSLocalizedString("stats.total_cards", comment: ""),
                    value: "\(stats.totalCards)",
                    unit: NSLocalizedString("stats.cards_unit", comment: "")
                )

                owner.thisMonthView.configure(
                    title: NSLocalizedString("stats.this_month", comment: ""),
                    value: "\(stats.thisMonthCards)",
                    unit: NSLocalizedString("stats.cards_unit", comment: "")
                )
            }
            .disposed(by: disposeBag)

        output.monthlyData
            .drive(with: self) { owner, data in
                let labels = data.map { $0.month }
                let values = data.map { CGFloat($0.count) }
                owner.monthlyChartView.configure(labels: labels, values: values)
            }
            .disposed(by: disposeBag)

        output.weekdayData
            .drive(with: self) { owner, data in
                let labels = data.map { $0.weekday }
                let values = data.map { CGFloat($0.count) }
                owner.weekdayChartView.configure(labels: labels, values: values)
            }
            .disposed(by: disposeBag)

        output.timeData
            .drive(with: self) { owner, data in
                let labels = data.map { $0.timeOfDay }
                let values = data.map { CGFloat($0.count) }
                owner.timeChartView.configure(labels: labels, values: values)
            }
            .disposed(by: disposeBag)

        output.moodData
            .drive(with: self) { owner, data in
                let labels = data.map { $0.mood.rawValue.capitalized }
                let values = data.map { CGFloat($0.count) }
                owner.moodChartView.configure(labels: labels, values: values)
            }
            .disposed(by: disposeBag)
    }
}

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
                .font: FontSystem.galmuriMono(size: 9),
                .foregroundColor: UIColor.black
            ]
            let labelSize = labelText.size(withAttributes: attributes)
            let labelX = x + (width - labelSize.width) / 2
            let labelY = rect.height - 28
            labelText.draw(at: CGPoint(x: labelX, y: labelY), withAttributes: attributes)
        }
    }
}

final class ListItemView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor(hex: "#D2D1E4").withAlphaComponent(0.2)
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    func configure(items: [String]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if items.isEmpty {
            let label = UILabel()
            label.text = NSLocalizedString("stats.no_data", comment: "")
            label.font = FontSystem.galmuriMono(size: 12)
            label.textColor = UIColor(hex: "#666666")
            stackView.addArrangedSubview(label)
        } else {
            for item in items {
                let label = UILabel()
                label.text = "• \(item)"
                label.font = FontSystem.galmuriMono(size: 12)
                label.textColor = .black
                stackView.addArrangedSubview(label)
            }
        }
    }
}

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
        backgroundColor = UIColor(hex: "#D2D1E4").withAlphaComponent(0.2)
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
            textLayer.font = FontSystem.galmuriMono(size: 10)
            textLayer.fontSize = 10
            textLayer.foregroundColor = ColorSystem.black.cgColor
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale

            let textSize = (labelText as NSString).size(withAttributes: [.font: FontSystem.galmuriMono(size: 10)])
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
