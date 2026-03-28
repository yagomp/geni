import SwiftUI

struct StreakCalendarView: View {
    let streakCount: Int
    let completedDates: Set<String>

    private let milestones = [3, 7, 14, 30]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var last30Days: [DayInfo] {
        let calendar = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let todayStr = fmt.string(from: today)

        return (0..<30).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dateStr = fmt.string(from: date)
            let weekday = calendar.component(.weekday, from: date)
            let dayNum = calendar.component(.day, from: date)
            return DayInfo(
                dateString: dateStr,
                dayNumber: dayNum,
                weekday: weekday,
                isToday: dateStr == todayStr,
                isCompleted: completedDates.contains(dateStr)
            )
        }
    }

    var body: some View {
        VStack(spacing: iPadScale.isIPad ? 28 : 20) {
            // Streak header
            VStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: iPadScale.isIPad ? 64 : 48))

                Text("\(streakCount)")
                    .font(.system(size: iPadScale.isIPad ? 56 : 42, weight: .black, design: .rounded))

                Text(L.s(.dayStreak))
                    .font(.system(size: iPadScale.isIPad ? 22 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, iPadScale.isIPad ? 24 : 16)

            // Milestones
            HStack(spacing: iPadScale.isIPad ? 20 : 12) {
                ForEach(milestones, id: \.self) { milestone in
                    let reached = streakCount >= milestone
                    VStack(spacing: 4) {
                        ZStack {
                            Rectangle()
                                .fill(reached ? GeniColor.orange : GeniColor.lightGray)
                                .frame(width: iPadScale.isIPad ? 56 : 44, height: iPadScale.isIPad ? 56 : 44)
                                .overlay(
                                    Rectangle()
                                        .stroke(GeniColor.border, lineWidth: 2)
                                )

                            Text(reached ? "🔥" : "🔒")
                                .font(.system(size: iPadScale.isIPad ? 24 : 20))
                        }

                        Text("\(milestone)")
                            .font(.system(size: iPadScale.isIPad ? 16 : 13, weight: .bold, design: .rounded))
                            .foregroundStyle(reached ? .primary : .secondary)
                    }
                    .scaleEffect(reached && streakCount == milestone ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4), value: reached)
                }
            }
            .padding(.horizontal, iPadScale.padding)
            .padding(.vertical, iPadScale.isIPad ? 16 : 12)
            .brutalistCard(color: GeniColor.lightYellow)

            // Weekday headers
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(weekdayLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: iPadScale.isIPad ? 14 : 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 6) {
                    // Leading spacers for first week alignment
                    let firstWeekday = last30Days.first?.weekday ?? 2
                    let mondayOffset = (firstWeekday + 5) % 7 // Convert to Mon=0
                    ForEach(0..<mondayOffset, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: iPadScale.isIPad ? 44 : 36)
                    }

                    ForEach(last30Days, id: \.dateString) { day in
                        ZStack {
                            Rectangle()
                                .fill(dayColor(for: day))
                                .frame(height: iPadScale.isIPad ? 44 : 36)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            day.isToday ? GeniColor.yellow : GeniColor.border.opacity(0.3),
                                            lineWidth: day.isToday ? 3 : 1
                                        )
                                )

                            Text("\(day.dayNumber)")
                                .font(.system(size: iPadScale.isIPad ? 15 : 12, weight: day.isToday ? .black : .medium, design: .rounded))
                                .foregroundStyle(day.isCompleted ? .white : .primary)
                        }
                    }
                }
            }
            .padding(iPadScale.isIPad ? 20 : 14)
            .brutalistCard()

            Spacer()
        }
        .padding(.horizontal, iPadScale.padding)
        .background(GeniColor.background)
    }

    private func dayColor(for day: DayInfo) -> Color {
        if day.isCompleted {
            return GeniColor.green
        }
        return GeniColor.lightGray.opacity(0.5)
    }

    private var weekdayLabels: [String] {
        if L.isNorwegian {
            return ["Ma", "Ti", "On", "To", "Fr", "Lø", "Sø"]
        }
        return ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    }
}

private struct DayInfo: Identifiable {
    var id: String { dateString }
    let dateString: String
    let dayNumber: Int
    let weekday: Int
    let isToday: Bool
    let isCompleted: Bool
}
