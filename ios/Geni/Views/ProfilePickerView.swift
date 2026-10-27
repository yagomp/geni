import SwiftUI

struct ProfilePickerView: View {
    let profiles: [ChildProfile]
    let onSelect: (ChildProfile) -> Void
    let onAddProfile: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            GeniColor.background.ignoresSafeArea()


            VStack(spacing: 32) {
                Text(L.s(.selectProfile))
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.border)

                CenteredWrapLayout(minTileWidth: 140, maxTileWidth: 180, spacing: 20) {
                    ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                        let avatar = AvatarOption.find(profile.avatarId)
                        Button {
                            HapticManager.impact(.medium)
                            onSelect(profile)
                        } label: {
                            VStack(spacing: 12) {
                                Text(avatar.emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 80, height: 80)
                                    .softSurface(.white)

                                Text(profile.nickname)
                                    .font(.system(.headline, design: .rounded, weight: .bold))
                                    .foregroundStyle(GeniColor.border)

                                Text("\(profile.age) \(L.s(.age).lowercased())")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.black)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .softSurface(GeniColor.card)
                        }
                        .accessibilityIdentifier("picker.profile.\(profile.nickname)")
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: appeared)
                    }

                    Button {
                        HapticManager.selection()
                        onAddProfile()
                    } label: {
                        VStack(spacing: 12) {
                            Text("➕")
                                .font(.system(size: 36))
                                .frame(width: 80, height: 80)
                                .softSurface(GeniColor.blue.soft(0.12))

                            Text(L.s(.addProfile))
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(GeniColor.border)

                            Text(" ")
                                .font(.system(.caption, design: .rounded))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .softSurface(GeniColor.card)
                    }
                    .accessibilityIdentifier("picker.add")
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(Double(profiles.count) * 0.1), value: appeared)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear { appeared = true }
    }
}

/// Wraps tiles into rows that fit the width and centres every row, including a short last row.
private struct CenteredWrapLayout: Layout {
    let minTileWidth: CGFloat
    let maxTileWidth: CGFloat
    let spacing: CGFloat

    private struct Arrangement {
        var tileWidth: CGFloat
        var rows: [Range<Int>]
    }

    private func arrange(count: Int, width: CGFloat) -> Arrangement {
        let columns = max(1, Int((width + spacing) / (minTileWidth + spacing)))
        let tileWidth = min(maxTileWidth, (width - CGFloat(columns - 1) * spacing) / CGFloat(columns))
        let rows = stride(from: 0, to: count, by: columns).map { $0..<min($0 + columns, count) }
        return Arrangement(tileWidth: tileWidth, rows: rows)
    }

    private func rowHeights(_ arrangement: Arrangement, _ subviews: Subviews) -> [CGFloat] {
        let proposal = ProposedViewSize(width: arrangement.tileWidth, height: nil)
        return arrangement.rows.map { row in
            row.map { subviews[$0].sizeThatFits(proposal).height }.max() ?? 0
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? maxTileWidth * CGFloat(subviews.count) + spacing * CGFloat(max(subviews.count - 1, 0))
        let arrangement = arrange(count: subviews.count, width: width)
        let heights = rowHeights(arrangement, subviews)
        let height = heights.reduce(0, +) + spacing * CGFloat(max(heights.count - 1, 0))
        let widest = arrangement.rows.map(\.count).max() ?? 0
        let usedWidth = CGFloat(widest) * arrangement.tileWidth + spacing * CGFloat(max(widest - 1, 0))
        return CGSize(width: usedWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(count: subviews.count, width: bounds.width)
        let heights = rowHeights(arrangement, subviews)
        var y = bounds.minY
        for (row, height) in zip(arrangement.rows, heights) {
            let rowWidth = CGFloat(row.count) * arrangement.tileWidth + spacing * CGFloat(row.count - 1)
            var x = bounds.midX - rowWidth / 2
            for index in row {
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: arrangement.tileWidth, height: height)
                )
                x += arrangement.tileWidth + spacing
            }
            y += height + spacing
        }
    }
}
