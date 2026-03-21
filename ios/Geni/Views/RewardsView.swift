import SwiftUI

struct RewardsView: View {
    let rewards: RewardState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GeniColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        statsSection
                        xpSection
                        badgesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L.s(.rewards))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.s(.done)) { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(icon: "dollarsign.circle.fill", value: "\(rewards.coins)", label: L.s(.coins), color: GeniColor.yellow)
            StatCard(icon: "flame.fill", value: "\(rewards.streakCount)", label: L.s(.streak), color: GeniColor.orange)
            StatCard(icon: "star.fill", value: "\(rewards.level)", label: L.s(.level), color: GeniColor.purple)
        }
    }

    private var xpSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text(L.s(.level))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text("\(rewards.level)")
                    .font(.system(.headline, design: .rounded, weight: .black))
                    .foregroundStyle(GeniColor.purple)
                Spacer()
                Text("\(rewards.xp)/\(rewards.xpForNextLevel) \(L.s(.xp))")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(GeniColor.purple)
                        .frame(width: geo.size.width * rewards.xpProgress)
                }
                .overlay(Rectangle().stroke(GeniColor.border, lineWidth: 3))
            }
            .frame(height: 16)
        }
        .padding(16)
        .brutalistCard(color: GeniColor.card)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.s(.badges))
                .font(.system(.headline, design: .rounded, weight: .bold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(Badge.all) { badge in
                    let isUnlocked = rewards.badgesUnlocked.contains(badge.id)

                    VStack(spacing: 8) {
                        Image(systemName: badge.icon)
                            .font(.title)
                            .foregroundStyle(isUnlocked ? badge.color : .gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .background(isUnlocked ? badge.color.opacity(0.15) : Color.gray.opacity(0.05))
                            .overlay(
                                Rectangle()
                                    .stroke(isUnlocked ? badge.color : .gray.opacity(0.2), lineWidth: 2)
                            )

                        Text(L.s(badge.titleKey))
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(isUnlocked ? GeniColor.border : .gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(L.s(badge.descriptionKey))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .multilineTextAlignment(.center)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .brutalistCard(color: isUnlocked ? GeniColor.card : Color.gray.opacity(0.05), borderWidth: isUnlocked ? 3 : 1)
                    .opacity(isUnlocked ? 1 : 0.6)
                }
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(GeniColor.border)

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .brutalistCard(color: GeniColor.card)
    }
}
