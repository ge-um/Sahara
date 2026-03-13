//
//  WidgetEntryView.swift
//  SaharaWidget
//
//  Created by 금가경 on 3/11/26.
//

import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    let entry: SaharaWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            cardView
                .widgetURL(cardURL)
        }
    }

    private var cardURL: URL? {
        guard let cardId = entry.cardId else { return nil }
        return URL(string: "\(AppGroupContainer.widgetURLScheme)://card/\(cardId)")
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text(NSLocalizedString("widget.empty_message", comment: ""))
                .font(.custom("Galmuri11-Bold", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cardView: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = entry.thumbnailImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                gradientOverlay(height: geometry.size.height)

                VStack(alignment: .leading, spacing: 4) {
                    Spacer()

                    if entry.isOnThisDay {
                        onThisDayBadge
                    }

                    if let cardDate = entry.cardDate {
                        Text(formattedDate(cardDate))
                            .font(.custom("Galmuri11-Bold", size: family == .systemLarge ? 16 : 13))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if family == .systemLarge, let memo = entry.memo, !memo.isEmpty {
                        Text(memo)
                            .font(.custom("Galmuri14", size: 16))
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func gradientOverlay(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            Spacer()

            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: height * 0.6)
        }
    }

    private var onThisDayBadge: some View {
        Text(NSLocalizedString("widget.on_this_day", comment: ""))
            .font(.custom("Galmuri11-Bold", size: 12))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.3)))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("widget.date_format", comment: "")
        return formatter.string(from: date)
    }
}
