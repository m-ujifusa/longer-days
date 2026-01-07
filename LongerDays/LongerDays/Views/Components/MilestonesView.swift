import SwiftUI

struct MilestonesView: View {
    let milestones: [Milestone]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Milestones")
                    .font(.headline)
                    .foregroundColor(Theme.primaryText)
                Spacer()
            }

            if milestones.isEmpty {
                Text("No milestones to track")
                    .font(.subheadline)
                    .foregroundColor(Theme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                ForEach(displayedMilestones) { milestone in
                    milestoneRow(milestone)
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    // Show up to 3 milestones: prioritize upcoming, then recent achieved
    private var displayedMilestones: [Milestone] {
        let upcoming = milestones.filter { !$0.isAchieved }.prefix(2)
        let achieved = milestones.filter { $0.isAchieved }.prefix(3 - upcoming.count)
        return Array(upcoming) + Array(achieved)
    }

    private func milestoneRow(_ milestone: Milestone) -> some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: milestone.isAchieved ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(milestone.isAchieved ? Theme.accent : Theme.secondaryText)

            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.type.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(milestone.isAchieved ? Theme.secondaryText : Theme.primaryText)

                if !milestone.isAchieved, let days = milestone.daysUntil {
                    Text("\(days) days")
                        .font(.caption)
                        .foregroundColor(Theme.accent)
                }
            }

            Spacer()

            if milestone.isAchieved {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accent)
            } else if let days = milestone.daysUntil {
                Text("\(days)d")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.accentSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 20) {
            MilestonesView(milestones: [
                Milestone(type: .earliestSunsetBehind, isAchieved: true, achievedDate: Date()),
                Milestone(type: .tenHoursDaylight, isAchieved: false, daysUntil: 12),
                Milestone(type: .oneHourGained, isAchieved: false, daysUntil: 28)
            ])

            MilestonesView(milestones: [])
        }
        .padding()
    }
}
