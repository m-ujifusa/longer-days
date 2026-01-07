import SwiftUI

struct ProgressArcView: View {
    let progress: Double  // 0.0 to 1.0
    let isGainingDaylight: Bool
    let startLabel: String
    let endLabel: String

    private let arcThickness: CGFloat = 8
    private let markerSize: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = min(width, height * 2) / 2 - arcThickness - markerSize / 2

            ZStack {
                // Background arc
                ArcShape(startAngle: .degrees(180), endAngle: .degrees(0))
                    .stroke(
                        Theme.cardBackground,
                        style: StrokeStyle(lineWidth: arcThickness, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius)

                // Progress arc with gradient
                ArcShape(startAngle: .degrees(180), endAngle: progressAngle)
                    .stroke(
                        arcGradient,
                        style: StrokeStyle(lineWidth: arcThickness, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius)

                // Progress marker
                Circle()
                    .fill(Theme.progressMarker)
                    .frame(width: markerSize, height: markerSize)
                    .shadow(color: Theme.progressMarker.opacity(0.6), radius: 8, x: 0, y: 0)
                    .offset(markerOffset(radius: radius))

                // Labels
                VStack {
                    Spacer()
                    HStack {
                        Text(startLabel)
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText)
                        Spacer()
                        Text(endLabel)
                            .font(.caption)
                            .foregroundColor(Theme.secondaryText)
                    }
                    .padding(.horizontal, 8)
                }
                .frame(width: radius * 2 + 40, height: radius + 24)
            }
            .frame(width: width, height: height)
        }
    }

    private var progressAngle: Angle {
        // Map progress (0-1) to angle (180° to 0°)
        let angle = 180 - (progress * 180)
        return .degrees(angle)
    }

    private var arcGradient: AngularGradient {
        if isGainingDaylight {
            return AngularGradient(
                gradient: Gradient(colors: [Theme.arcStart, Theme.arcMiddle, Theme.arcEnd]),
                center: .bottom,
                startAngle: .degrees(180),
                endAngle: .degrees(0)
            )
        } else {
            return AngularGradient(
                gradient: Gradient(colors: [Theme.negative.opacity(0.7), Theme.negative, Theme.negative.opacity(0.7)]),
                center: .bottom,
                startAngle: .degrees(180),
                endAngle: .degrees(0)
            )
        }
    }

    private func markerOffset(radius: CGFloat) -> CGSize {
        // Calculate position on arc based on progress
        // Progress 0 = left (180°), Progress 1 = right (0°)
        let angle = Double.pi - (progress * Double.pi)
        let x = cos(angle) * radius
        let y = -sin(angle) * radius  // Negative because SwiftUI y-axis is inverted

        return CGSize(width: x, height: y + radius / 2)
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        return path
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 40) {
            ProgressArcView(
                progress: 0.3,
                isGainingDaylight: true,
                startLabel: "Dec 21",
                endLabel: "Jun 21"
            )
            .frame(height: 120)
            .padding(.horizontal, 40)

            ProgressArcView(
                progress: 0.7,
                isGainingDaylight: false,
                startLabel: "Jun 21",
                endLabel: "Dec 21"
            )
            .frame(height: 120)
            .padding(.horizontal, 40)
        }
    }
}
