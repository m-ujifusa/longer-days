import SwiftUI

struct SunArcView: View {
    let sunrise: Date
    let sunset: Date
    let firstLight: Date?
    let lastLight: Date?
    let currentTime: Date

    private let arcHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            // Arc visualization
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = arcHeight
                let horizonY = height * 0.65

                ZStack {
                    // Background gradient (day above horizon, night below)
                    VStack(spacing: 0) {
                        // Day sky - using Theme colors
                        LinearGradient(
                            colors: [
                                Theme.accent.opacity(0.15),
                                Theme.accentSecondary.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: horizonY)

                        // Night
                        Theme.background
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Calculate sunrise/sunset x positions
                    let sunriseX = xPosition(for: sunrise, width: width)
                    let sunsetX = xPosition(for: sunset, width: width)

                    // Vertical time markers
                    ForEach([0.0, 0.25, 0.5, 0.75], id: \.self) { fraction in
                        Path { path in
                            let x = width * fraction
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }

                    // Sun arc path (using actual sunrise/sunset times)
                    let arcPath = createArcPath(
                        width: width,
                        height: height,
                        horizonY: horizonY,
                        sunriseX: sunriseX,
                        sunsetX: sunsetX
                    )

                    arcPath
                        .stroke(
                            Theme.accentSecondary.opacity(0.6),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )

                    // Horizon line (drawn after arc so it's on top)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: horizonY))
                        path.addLine(to: CGPoint(x: width, y: horizonY))
                    }
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)

                    // Sunrise dot - arc now crosses horizon at actual sunrise position
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .position(x: sunriseX, y: horizonY)

                    // Sunset dot - arc now crosses horizon at actual sunset position
                    Circle()
                        .fill(Theme.accentSecondary)
                        .frame(width: 8, height: 8)
                        .position(x: sunsetX, y: horizonY)

                    // Twilight dots (on the arc at their actual time positions)
                    if let firstLight = firstLight {
                        let firstLightPos = positionOnArc(
                            for: firstLight,
                            width: width,
                            height: height,
                            horizonY: horizonY,
                            sunriseX: sunriseX,
                            sunsetX: sunsetX
                        )
                        Circle()
                            .fill(Theme.secondaryText.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .position(firstLightPos)
                    }

                    if let lastLight = lastLight {
                        let lastLightPos = positionOnArc(
                            for: lastLight,
                            width: width,
                            height: height,
                            horizonY: horizonY,
                            sunriseX: sunriseX,
                            sunsetX: sunsetX
                        )
                        Circle()
                            .fill(Theme.secondaryText.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .position(lastLightPos)
                    }

                    // Current sun position
                    let sunPosition = positionOnArc(
                        for: currentTime,
                        width: width,
                        height: height,
                        horizonY: horizonY,
                        sunriseX: sunriseX,
                        sunsetX: sunsetX
                    )

                    // Sun glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.accent,
                                    Theme.accent.opacity(0.5),
                                    Theme.accent.opacity(0)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .position(sunPosition)

                    // Sun circle
                    Circle()
                        .fill(Theme.progressMarker)
                        .frame(width: 16, height: 16)
                        .position(sunPosition)
                }
            }
            .frame(height: arcHeight)

            // Time labels
            HStack {
                Text("12AM")
                Spacer()
                Text("6AM")
                Spacer()
                Text("12PM")
                Spacer()
                Text("6PM")
            }
            .font(.caption)
            .foregroundColor(Theme.secondaryText)
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
    }

    // MARK: - Arc Calculations

    private func xPosition(for time: Date, width: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: time)
        let secondsSinceMidnight = time.timeIntervalSince(startOfDay)
        let totalSecondsInDay: TimeInterval = 24 * 60 * 60
        let fraction = CGFloat(secondsSinceMidnight / totalSecondsInDay)
        return width * fraction
    }

    private func createArcPath(width: CGFloat, height: CGFloat, horizonY: CGFloat, sunriseX: CGFloat, sunsetX: CGFloat) -> Path {
        Path { path in
            let amplitude = horizonY * 0.5  // Controls arc height

            let steps = 100
            for i in 0...steps {
                let fraction = CGFloat(i) / CGFloat(steps)
                let x = width * fraction

                let y = calculateArcY(
                    x: x,
                    width: width,
                    horizonY: horizonY,
                    amplitude: amplitude,
                    sunriseX: sunriseX,
                    sunsetX: sunsetX
                )

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }

    private func calculateArcY(x: CGFloat, width: CGFloat, horizonY: CGFloat, amplitude: CGFloat, sunriseX: CGFloat, sunsetX: CGFloat) -> CGFloat {
        // Piecewise cosine curve that crosses horizon exactly at sunrise/sunset
        // - During day: angle goes from -π/2 (sunrise) to 0 (noon) to +π/2 (sunset)
        // - Before sunrise: angle goes from -π (midnight) to -π/2 (sunrise)
        // - After sunset: angle goes from +π/2 (sunset) to +π (midnight)

        let angle: CGFloat

        if x >= sunriseX && x <= sunsetX {
            // Daytime: map [sunriseX, sunsetX] to [-π/2, +π/2]
            let dayFraction = (x - sunriseX) / (sunsetX - sunriseX)
            angle = (dayFraction - 0.5) * .pi
        } else if x < sunriseX {
            // Before sunrise: map [0, sunriseX] to [-π, -π/2]
            let nightFraction = x / sunriseX
            angle = -.pi + nightFraction * (.pi / 2)
        } else {
            // After sunset: map [sunsetX, width] to [+π/2, +π]
            let nightFraction = (x - sunsetX) / (width - sunsetX)
            angle = .pi / 2 + nightFraction * (.pi / 2)
        }

        // cos gives: 1 at noon (angle=0), 0 at sunrise/sunset (angle=±π/2), -1 at midnight (angle=±π)
        return horizonY - cos(angle) * amplitude
    }

    private func positionOnArc(for time: Date, width: CGFloat, height: CGFloat, horizonY: CGFloat, sunriseX: CGFloat, sunsetX: CGFloat) -> CGPoint {
        let x = xPosition(for: time, width: width)
        let amplitude = horizonY * 0.5

        let y = calculateArcY(
            x: x,
            width: width,
            horizonY: horizonY,
            amplitude: amplitude,
            sunriseX: sunriseX,
            sunsetX: sunsetX
        )

        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack {
            SunArcView(
                sunrise: Calendar.current.date(bySettingHour: 7, minute: 51, second: 0, of: Date())!,
                sunset: Calendar.current.date(bySettingHour: 16, minute: 49, second: 0, of: Date())!,
                firstLight: Calendar.current.date(bySettingHour: 7, minute: 17, second: 0, of: Date())!,
                lastLight: Calendar.current.date(bySettingHour: 17, minute: 22, second: 0, of: Date())!,
                currentTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!
            )
            .padding()
        }
    }
}
