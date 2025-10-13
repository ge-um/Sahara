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
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .black
        return label
    }()

    private let monthlyChartView = SimpleBarChartView()

    private let weekdayTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.weekday_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .black
        return label
    }()

    private let weekdayChartView = SimpleBarChartView()

    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.time_pattern", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .black
        return label
    }()

    private let timeChartView = SimpleBarChartView()

    private let moodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("stats.mood_distribution", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
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
        view.applyGradientWithDots(.pinkToBlue, dotSize: 5, spacing: 32, dotColor: .white)

        timeChartView.setBarGradient(.yellowGreen)
        weekdayChartView.setBarGradient(.yellowGreen)
        monthlyChartView.setBarGradient(.yellowGreen)

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

//        moodChartView.snp.makeConstraints { make in
//            make.height.equalTo(250)
//        }
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

//        output.moodData
//            .drive(with: self) { owner, data in
//                let labels = data.map { $0.mood.rawValue.capitalized }
//                let values = data.map { CGFloat($0.count) }
//                owner.moodChartView.configure(labels: labels, values: values)
//            }
//            .disposed(by: disposeBag)
    }
}
