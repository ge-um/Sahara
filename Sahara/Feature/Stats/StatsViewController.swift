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

    private let customNavigationBar = CustomNavigationBar()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
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

    private let patternHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "📊 " + NSLocalizedString("stats.my_pattern_header", comment: "")
        label.font = FontSystem.galmuriMono(size: 16)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private lazy var weekdayInsightLabel: PaddedLabel = {
        let label = PaddedLabel(padding: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        label.numberOfLines = 0
        label.backgroundColor = .token(.backgroundGlass)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.textAlignment = .left
        return label
    }()

    private lazy var timeInsightLabel: PaddedLabel = {
        let label = PaddedLabel(padding: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        label.numberOfLines = 0
        label.backgroundColor = .token(.backgroundGlass)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.textAlignment = .left
        return label
    }()

    private lazy var thisMonthInsightLabel: PaddedLabel = {
        let label = PaddedLabel(padding: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        label.numberOfLines = 0
        label.backgroundColor = .token(.backgroundGlass)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.textAlignment = .left
        return label
    }()

    private let timeChartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.time_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let weekdayChartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.weekday_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let monthlyChartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.monthly_chart", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let monthlyChartView = SimpleBarChartView()
    private let weekdayChartView = SimpleBarChartView()
    private let timeChartView = SimpleBarChartView()

    private let moodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.mood_distribution", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
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
        updateLeftButtonForCurrentMode()
    }

    private func updateLeftButtonForCurrentMode() {
        if let toggler = navigationController?.parent as? SidebarToggleable, toggler.isSidebarMode {
            customNavigationBar.showLeftButton()
            customNavigationBar.setLeftButtonImage(UIImage(systemName: "sidebar.leading"))
            customNavigationBar.onLeftButtonTapped = { [weak toggler] in
                toggler?.toggleSidebar()
            }
        } else {
            customNavigationBar.hideLeftButton()
        }
    }

    private func configureUI() {
        view.bindBackgroundTheme(disposedBy: disposeBag)

        timeChartView.setBarGradient(.highlight)
        weekdayChartView.setBarGradient(.highlight)
        monthlyChartView.setBarGradient(.highlight)

        view.addSubview(customNavigationBar)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(basicStatsStackView)
        contentStackView.addArrangedSubview(patternHeaderLabel)
        contentStackView.addArrangedSubview(weekdayInsightLabel)
        contentStackView.addArrangedSubview(timeInsightLabel)
        contentStackView.addArrangedSubview(thisMonthInsightLabel)
        contentStackView.addArrangedSubview(timeChartTitleLabel)
        contentStackView.addArrangedSubview(timeChartView)
        contentStackView.addArrangedSubview(weekdayChartTitleLabel)
        contentStackView.addArrangedSubview(weekdayChartView)
        contentStackView.addArrangedSubview(monthlyChartTitleLabel)
        contentStackView.addArrangedSubview(monthlyChartView)
//        contentStackView.addArrangedSubview(moodTitleLabel)
//        contentStackView.addArrangedSubview(moodChartView)

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
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(20)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(600)
            make.width.equalTo(scrollView.snp.width).offset(-40).priority(.medium)
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

//        moodChartView.snp.makeConstraints { make in
//            make.height.equalTo(250)
//        }
    }

    private func bind() {
        let input = StatsViewModel.Input()
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

        output.weekdayInsight
            .drive(with: self) { owner, insight in
                owner.weekdayInsightLabel.text = "🗓️ " + insight
            }
            .disposed(by: disposeBag)

        output.timeInsight
            .drive(with: self) { owner, insight in
                owner.timeInsightLabel.text = insight
            }
            .disposed(by: disposeBag)

        output.thisMonthInsight
            .drive(with: self) { owner, insight in
                owner.thisMonthInsightLabel.text = "📈 " + insight
            }
            .disposed(by: disposeBag)

//        output.moodData
//            .drive(with: self) { owner, data in
//                let labels = data.map { $0.mood.rawValue.capitalized }
//                let values = data.map { CGFloat($0.count) }
//                owner.moodChartView.configure(labels: labels, values: values)
//            }
//            .disposed(by: disposeBag)
    }
}

// MARK: - SidebarModeObserver

extension StatsViewController: SidebarModeObserver {
    func sidebarModeDidChange() {
        updateLeftButtonForCurrentMode()
    }
}

final class PaddedLabel: UILabel {
    private var padding: UIEdgeInsets

    init(padding: UIEdgeInsets) {
        self.padding = padding
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
    }
}
