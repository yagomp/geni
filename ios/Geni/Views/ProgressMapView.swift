import SwiftUI

struct ProgressMapView: View {
    let completedCount: Int
    let rewards: RewardState

    private let nodeColors: [Color] = [
        GeniColor.blue, GeniColor.green, GeniColor.pink,
        GeniColor.purple, GeniColor.orange, GeniColor.cyan,
        GeniColor.yellow
    ]

    var body: some View {
        let totalNodes = max(completedCount + 3, 10)

        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(GeniColor.blue)
                Text("\(completedCount)")
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)
                Text(L.s(.chaptersCompleted))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(0..<totalNodes, id: \.self) { index in
                            let isCompleted = index < completedCount
                            let isCurrent = index == completedCount
                            let isMilestone = (index + 1) % 5 == 0
                            let color = nodeColors[index % nodeColors.count]

                            HStack(spacing: 0) {
                                if index > 0 {
                                    pathSegment(completed: isCompleted, color: color)
                                }

                                nodeView(
                                    index: index,
                                    isCompleted: isCompleted,
                                    isCurrent: isCurrent,
                                    isMilestone: isMilestone,
                                    color: color
                                )
                                .id(index)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .contentMargins(.horizontal, 4)
                .scrollIndicators(.hidden)
                .onAppear {
                    proxy.scrollTo(max(completedCount - 1, 0), anchor: .center)
                }
            }
        }
        .padding(16)
        .brutalistCard(color: GeniColor.card, borderWidth: 3)
    }

    private func pathSegment(completed: Bool, color: Color) -> some View {
        Rectangle()
            .fill(completed ? GeniColor.green : Color.gray.opacity(0.2))
            .frame(width: 20, height: 4)
    }

    private func nodeView(index: Int, isCompleted: Bool, isCurrent: Bool, isMilestone: Bool, color: Color) -> some View {
        let size: CGFloat = isMilestone ? 48 : 36

        return ZStack {
            Rectangle()
                .fill(isCompleted ? GeniColor.green : (isCurrent ? GeniColor.cyan : .white))
                .frame(width: size, height: size)
                .overlay(
                    Rectangle()
                        .stroke(GeniColor.border, lineWidth: 3)
                )
                .background(
                    Rectangle()
                        .fill(GeniColor.border)
                        .offset(x: 3, y: 3)
                )

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(.white)
            } else if isMilestone && !isCurrent {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray.opacity(0.4))
            } else {
                Text("\(index + 1)")
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? .white : .gray.opacity(0.4))
            }
        }
    }
}
