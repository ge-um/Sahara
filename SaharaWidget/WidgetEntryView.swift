//
//  WidgetEntryView.swift
//  SaharaWidget
//
//  Created by 금가경 on 3/11/26.
//

import AppIntents
import SwiftUI
import WidgetKit

private enum WidgetDesignToken {
    enum GradientColor {
        static let tabBarTop = Color(red: 243/255, green: 242/255, blue: 255/255)
        static let tabBarBottom = Color(red: 210/255, green: 209/255, blue: 236/255)
    }

    enum TextColor {
        static let navigationButton = Color(red: 80/255, green: 78/255, blue: 120/255)
        static let placeholder = Color(red: 120/255, green: 118/255, blue: 150/255)
    }

    static var tabBarGradient: LinearGradient {
        LinearGradient(
            colors: [GradientColor.tabBarTop, GradientColor.tabBarBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct WidgetEntryView: View {
    let entry: SaharaWidgetEntry

    @Environment(\.widgetFamily) var family

    private var showNavigationButtons: Bool {
        !entry.isEmpty && entry.navigableCardCount > 1
    }

    var body: some View {
        Group {
            if entry.isEmpty {
                emptyView
                    .widgetURL(randomCardURL)
            } else {
                cardView
                    .overlay { navigationButtons }
                    .widgetURL(cardURL)
            }
        }
        .unredacted()
    }

    private var cardURL: URL? {
        guard let cardId = entry.cardId else { return nil }
        return URL(string: "\(AppGroupContainer.widgetURLScheme)://card/\(cardId)")
    }

    private var randomCardURL: URL? {
        URL(string: "\(AppGroupContainer.widgetURLScheme)://card/random")
    }

    private var emptyView: some View {
        VStack(spacing: family == .systemLarge ? 12 : 8) {
            Image("image")
                .resizable()
                .scaledToFit()
                .frame(width: family == .systemLarge ? 40 : 28,
                       height: family == .systemLarge ? 40 : 28)
                .foregroundColor(WidgetDesignToken.TextColor.placeholder)
            Text(NSLocalizedString("widget.select_photo", comment: ""))
                .font(.custom("Galmuri11", size: family == .systemLarge ? 13 : 10))
                .foregroundColor(WidgetDesignToken.TextColor.placeholder)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WidgetDesignToken.tabBarGradient)
    }

    @ViewBuilder
    private var cardView: some View {
        if let image = entry.thumbnailImage {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        if showNavigationButtons {
            let buttonSize: CGFloat = family == .systemLarge ? 36 : 30
            HStack {
                Button(intent: NavigateWidgetPhotoIntent(direction: .previous)) {
                    navigationButtonLabel("<", size: buttonSize)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(intent: NavigateWidgetPhotoIntent(direction: .next)) {
                    navigationButtonLabel(">", size: buttonSize)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, family == .systemLarge ? 12 : 8)
        }
    }

    private func navigationButtonLabel(_ symbol: String, size: CGFloat) -> some View {
        Text(symbol)
            .font(.custom("Galmuri11", size: size * 0.7))
            .foregroundColor(WidgetDesignToken.TextColor.navigationButton)
            .offset(
                x: symbol == "<" ? -size * 0.04 : size * 0.05,
                y: size * 0.03
            )
            .frame(width: size, height: size)
            .background(WidgetDesignToken.tabBarGradient)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
}
