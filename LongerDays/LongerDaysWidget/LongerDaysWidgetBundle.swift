//
//  LongerDaysWidgetBundle.swift
//  LongerDaysWidget
//
//  Created by Michael Ujifusa on 1/12/26.
//

import WidgetKit
import SwiftUI
import CoreLocation

@main
struct LongerDaysWidgetBundle: WidgetBundle {
    var body: some Widget {
        CumulativeWidget()
        DailyWidget()
        CombinedWidget()
    }
}

// MARK: - Timeline Entry

struct DaylightEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData?
}

// MARK: - Timeline Provider

struct DaylightTimelineProvider: TimelineProvider {
    typealias Entry = DaylightEntry

    func placeholder(in context: Context) -> DaylightEntry {
        DaylightEntry(date: Date(), widgetData: sampleData)
    }

    func getSnapshot(in context: Context, completion: @escaping (DaylightEntry) -> Void) {
        let entry = DaylightEntry(
            date: Date(),
            widgetData: SharedDataManager.shared.loadWidgetData() ?? sampleData
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaylightEntry>) -> Void) {
        let currentDate = Date()
        var widgetData = SharedDataManager.shared.loadWidgetData()

        if widgetData == nil {
            widgetData = calculateFreshData()
        }

        let entry = DaylightEntry(date: currentDate, widgetData: widgetData)

        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate)!)

        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func calculateFreshData() -> WidgetData? {
        guard let locationData = SharedDataManager.shared.loadLocation() else {
            return nil
        }

        let location = locationData.coordinate
        let locationName = locationData.name

        let today = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let solsticeInfo = SolsticeInfo(for: today)
        let (recentSolstice, _) = solsticeInfo.mostRecentSolstice(before: today)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let solsticeLabel = dateFormatter.string(from: recentSolstice)

        return WidgetData(
            lastUpdated: today,
            latitude: location.latitude,
            longitude: location.longitude,
            locationName: locationName,
            cumulativeChangeSeconds: SolarCalculator.cumulativeDaylightChangeSeconds(
                since: recentSolstice, to: today, at: location) ?? 0,
            dailyChangeSeconds: SolarCalculator.dailyChangeSeconds(
                from: yesterday, to: today, at: location) ?? 0,
            isGainingDaylight: solsticeInfo.season(for: today) == .gainingDaylight,
            solsticeLabel: solsticeLabel,
            progress: solsticeInfo.progressThroughHalfYear(for: today)
        )
    }

    private var sampleData: WidgetData {
        WidgetData(
            lastUpdated: Date(),
            latitude: 37.7749,
            longitude: -122.4194,
            locationName: "San Francisco",
            cumulativeChangeSeconds: 2820,
            dailyChangeSeconds: 138,
            isGainingDaylight: true,
            solsticeLabel: "Dec 21",
            progress: 0.15
        )
    }
}

// MARK: - Widget Definitions

struct CumulativeWidget: Widget {
    let kind = "CumulativeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaylightTimelineProvider()) { entry in
            CumulativeWidgetView(entry: entry)
                .containerBackground(Theme.background, for: .widget)
        }
        .configurationDisplayName("Daylight Gained")
        .description("Total daylight gained since the solstice")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DailyWidget: Widget {
    let kind = "DailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaylightTimelineProvider()) { entry in
            DailyWidgetView(entry: entry)
                .containerBackground(Theme.background, for: .widget)
        }
        .configurationDisplayName("Today's Change")
        .description("Daylight change compared to yesterday")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CombinedWidget: Widget {
    let kind = "CombinedWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaylightTimelineProvider()) { entry in
            CombinedWidgetView(entry: entry)
                .containerBackground(Theme.background, for: .widget)
        }
        .configurationDisplayName("Daylight Summary")
        .description("Today's change and total gained since solstice")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Cumulative Widget View

struct CumulativeWidgetView: View {
    let entry: DaylightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallCumulativeView
        case .systemMedium:
            mediumCumulativeView
        default:
            smallCumulativeView
        }
    }

    @ViewBuilder
    private var smallCumulativeView: some View {
        if let data = entry.widgetData {
            VStack(spacing: 4) {
                Text(data.cumulativeFormatted)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.gainColor(data.isGainingDaylight))
                    .minimumScaleFactor(0.7)

                Text("since \(data.solsticeLabel)")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)

                ProgressView(value: data.progress)
                    .tint(Theme.gainColor(data.isGainingDaylight))
                    .padding(.top, 8)
            }
        } else {
            noDataView
        }
    }

    @ViewBuilder
    private var mediumCumulativeView: some View {
        if let data = entry.widgetData {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daylight Gained")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)

                    Text(data.cumulativeFormatted)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gainColor(data.isGainingDaylight))

                    Text("since \(data.solsticeLabel)")
                        .font(.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                VStack {
                    Text("\(Int(data.progress * 100))%")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.primaryText)

                    Text("to solstice")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryText)
                }
            }
        } else {
            noDataView
        }
    }

    private var noDataView: some View {
        VStack {
            Image(systemName: "location.slash")
                .foregroundColor(Theme.secondaryText)
            Text("Open app to set location")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
        }
    }
}

// MARK: - Daily Widget View

struct DailyWidgetView: View {
    let entry: DaylightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallDailyView
        case .systemMedium:
            mediumDailyView
        default:
            smallDailyView
        }
    }

    @ViewBuilder
    private var smallDailyView: some View {
        if let data = entry.widgetData {
            VStack(spacing: 8) {
                Image(systemName: data.isGainingDaylight ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.gainColor(data.isGainingDaylight))

                Text(data.dailyFormatted)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.gainColor(data.isGainingDaylight))
                    .minimumScaleFactor(0.7)

                Text("today")
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        } else {
            noDataView
        }
    }

    @ViewBuilder
    private var mediumDailyView: some View {
        if let data = entry.widgetData {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: data.isGainingDaylight ? "sunrise.fill" : "sunset.fill")
                            .foregroundColor(Theme.accentSecondary)
                        Text("Today's Change")
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText)
                    }

                    Text(data.dailyFormatted)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gainColor(data.isGainingDaylight))

                    Text(data.isGainingDaylight ? "more daylight than yesterday" : "less daylight than yesterday")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)
                }

                Spacer()

                Image(systemName: data.isGainingDaylight ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Theme.gainColor(data.isGainingDaylight))
            }
        } else {
            noDataView
        }
    }

    private var noDataView: some View {
        VStack {
            Image(systemName: "location.slash")
                .foregroundColor(Theme.secondaryText)
            Text("Open app to set location")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
        }
    }
}

// MARK: - Combined Widget View

struct CombinedWidgetView: View {
    let entry: DaylightEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallCombinedView
        case .systemMedium:
            mediumCombinedView
        default:
            smallCombinedView
        }
    }

    @ViewBuilder
    private var smallCombinedView: some View {
        if let data = entry.widgetData {
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(data.cumulativeFormatted)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gainColor(data.isGainingDaylight))
                    Text("since \(data.solsticeLabel)")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.secondaryText)
                }

                Divider()
                    .background(Theme.secondaryText.opacity(0.3))

                HStack {
                    Image(systemName: data.isGainingDaylight ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .semibold))
                    Text(data.dailyFormatted)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("today")
                        .font(.system(size: 10))
                }
                .foregroundColor(Theme.gainColor(data.isGainingDaylight))
            }
        } else {
            noDataView
        }
    }

    @ViewBuilder
    private var mediumCombinedView: some View {
        if let data = entry.widgetData {
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("Total Gained")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)

                    Text(data.cumulativeFormatted)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.gainColor(data.isGainingDaylight))
                        .minimumScaleFactor(0.7)

                    Text("since \(data.solsticeLabel)")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Theme.secondaryText.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                VStack(spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(Theme.secondaryText)

                    HStack(spacing: 4) {
                        Image(systemName: data.isGainingDaylight ? "arrow.up" : "arrow.down")
                            .font(.system(size: 18, weight: .semibold))
                        Text(data.dailyFormatted)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(Theme.gainColor(data.isGainingDaylight))
                    .minimumScaleFactor(0.7)

                    Text(data.isGainingDaylight ? "gained" : "lost")
                        .font(.caption2)
                        .foregroundColor(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            noDataView
        }
    }

    private var noDataView: some View {
        VStack {
            Image(systemName: "location.slash")
                .foregroundColor(Theme.secondaryText)
            Text("Open app to set location")
                .font(.caption)
                .foregroundColor(Theme.secondaryText)
        }
    }
}
