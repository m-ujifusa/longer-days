import SwiftUI

struct CountdownsView: View {
    let daysSinceSolstice: Int
    let daysUntilEquinox: Int?
    let daysUntilNextSolstice: Int?
    let isGainingDaylight: Bool
    let recentSolsticeType: SolsticeInfo.SolsticeType
    let nextEquinoxType: SolsticeInfo.EquinoxType?
    let nextSolsticeType: SolsticeInfo.SolsticeType?

    var body: some View {
        VStack(spacing: 12) {
            countdownRow(
                value: daysSinceSolstice,
                label: "days since \(solsticeLabel(recentSolsticeType))",
                isSince: true
            )

            if let equinoxDays = daysUntilEquinox, let equinoxType = nextEquinoxType {
                countdownRow(
                    value: equinoxDays,
                    label: "days to \(equinoxLabel(equinoxType))",
                    isSince: false
                )
            }

            if let solsticeDays = daysUntilNextSolstice, let solsticeType = nextSolsticeType {
                countdownRow(
                    value: solsticeDays,
                    label: "days to \(solsticeLabel(solsticeType))",
                    isSince: false
                )
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func countdownRow(value: Int, label: String, isSince: Bool) -> some View {
        HStack {
            Text("\(value)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(isSince ? Theme.accent : Theme.primaryText)
                .frame(width: 50, alignment: .leading)

            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)

            Spacer()
        }
    }

    private func solsticeLabel(_ type: SolsticeInfo.SolsticeType) -> String {
        switch type {
        case .winter:
            return "winter solstice"
        case .summer:
            return "summer solstice"
        }
    }

    private func equinoxLabel(_ type: SolsticeInfo.EquinoxType) -> String {
        switch type {
        case .spring:
            return "spring equinox"
        case .fall:
            return "fall equinox"
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            // Winter to summer (gaining daylight)
            CountdownsView(
                daysSinceSolstice: 23,
                daysUntilEquinox: 54,
                daysUntilNextSolstice: 147,
                isGainingDaylight: true,
                recentSolsticeType: .winter,
                nextEquinoxType: .spring,
                nextSolsticeType: .summer
            )

            // Summer to winter (losing daylight)
            CountdownsView(
                daysSinceSolstice: 45,
                daysUntilEquinox: 32,
                daysUntilNextSolstice: 120,
                isGainingDaylight: false,
                recentSolsticeType: .summer,
                nextEquinoxType: .fall,
                nextSolsticeType: .winter
            )
        }
        .padding()
    }
}
