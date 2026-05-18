// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.

import SwiftUI

enum StudioTab: String, CaseIterable, Identifiable {
    case draw
    case paint
    case library
    case cloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .draw:
            "Draw"
        case .paint:
            "Paint"
        case .library:
            "Library"
        case .cloud:
            "Cloud"
        }
    }

    var icon: String {
        switch self {
        case .draw:
            "pencil.and.ruler.fill"
        case .paint:
            "paintpalette.fill"
        case .library:
            "square.stack.3d.up.fill"
        case .cloud:
            "icloud.and.arrow.up.fill"
        }
    }
}

enum GoldStudioTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.02, blue: 0.01),
            Color(red: 0.12, green: 0.08, blue: 0.03),
            Color(red: 0.22, green: 0.16, blue: 0.08),
            Color(red: 0.05, green: 0.03, blue: 0.01)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let metallic = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.92, blue: 0.72),
            Color(red: 0.88, green: 0.71, blue: 0.33),
            Color(red: 0.67, green: 0.49, blue: 0.17)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sparkle = LinearGradient(
        colors: [
            Color.white.opacity(0.85),
            Color(red: 0.98, green: 0.84, blue: 0.48),
            Color(red: 0.72, green: 0.49, blue: 0.18)
        ],
        startPoint: .top,
        endPoint: .bottomTrailing
    )
}

struct GoldPanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color(red: 0.87, green: 0.68, blue: 0.27).opacity(0.14),
                                        Color.black.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(GoldStudioTheme.sparkle.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 22, y: 12)
            )
    }
}

extension View {
    func goldPanel() -> some View {
        modifier(GoldPanelModifier())
    }
}

struct GoldMetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(GoldStudioTheme.sparkle)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.65))
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(14)
        .goldPanel()
    }
}

struct SessionLibraryView: View {
    let sessions: [DrawingSession]
    let favorites: [FavoriteTrack]
    let onSelectTab: (StudioTab) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                libraryHero

                GoldMetricCard(
                    title: "Saved Sessions",
                    value: "\(sessions.count)",
                    icon: "square.stack.3d.up.fill"
                )

                if sessions.isEmpty {
                    emptyState(
                        title: "No saved studio sessions yet",
                        message: "Use the save actions in Draw or Paint to capture work into the library.",
                        actionTitle: "Open Draw Studio",
                        action: { onSelectTab(.draw) }
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Recent Sessions")
                        ForEach(sessions.prefix(6)) { session in
                            Button {
                                onSelectTab(session.sessionType == "painting" ? .paint : .draw)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: session.sessionType == "painting" ? "paintpalette.fill" : "scribble.variable")
                                        .foregroundStyle(GoldStudioTheme.sparkle)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(session.title)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text("\(session.strokeCount) strokes • \(session.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(Color.white.opacity(0.6))
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.forward.square")
                                        .foregroundStyle(Color.white.opacity(0.5))
                                }
                                .padding(14)
                                .goldPanel()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Favorite Tracks")

                    if favorites.isEmpty {
                        emptyState(
                            title: "No favorite tracks yet",
                            message: "Use the heart button in the player or playlist to pin the soundtrack you love.",
                            actionTitle: "Open Cloud Studio",
                            action: { onSelectTab(.draw) }
                        )
                    } else {
                        ForEach(favorites.prefix(6)) { favorite in
                            HStack(spacing: 12) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(GoldStudioTheme.sparkle)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(favorite.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text(favorite.composer)
                                        .font(.caption)
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                                Spacer()
                                Text(favorite.addedAt.formatted(date: .numeric, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .padding(14)
                            .goldPanel()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var libraryHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Curated Library")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(GoldStudioTheme.sparkle)
            Text("Every saved sketch, painting, and favorite soundtrack is ready to route back into the studio.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(18)
        .goldPanel()
    }

    private func emptyState(
        title: String,
        message: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.66))
            Button(actionTitle, action: action)
                .buttonStyle(.plain)
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(GoldStudioTheme.sparkle))
        }
        .padding(16)
        .goldPanel()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.92))
    }
}

struct CloudBackupView: View {
    let settings: AppSettings?
    let snapshots: [BackupSnapshot]
    let sessionCount: Int
    let favoriteCount: Int
    let onCloudKitToggle: (Bool) -> Void
    let onICloudToggle: (Bool) -> Void
    let onBackup: (BackupProvider) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                backupHero

                HStack(spacing: 12) {
                    GoldMetricCard(title: "Sessions", value: "\(sessionCount)", icon: "square.stack.3d.up.fill")
                    GoldMetricCard(title: "Favorites", value: "\(favoriteCount)", icon: "heart.fill")
                }

                if let settings {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle("Backup Controls")
                        ToggleRow(
                            title: "CloudKit Sync",
                            subtitle: "Keep the SwiftData store synced through the CloudKit-backed container.",
                            isOn: Binding(
                                get: { settings.cloudKitSyncEnabled },
                                set: onCloudKitToggle
                            )
                        )
                        ToggleRow(
                            title: "iCloud Recovery Backup",
                            subtitle: "Record recovery-ready iCloud checkpoints from inside the app.",
                            isOn: Binding(
                                get: { settings.iCloudBackupEnabled },
                                set: onICloudToggle
                            )
                        )
                    }
                    .padding(16)
                    .goldPanel()

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Manual Checkpoints")
                        ForEach(BackupProvider.allCases) { provider in
                            Button {
                                onBackup(provider)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(provider.label)
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(provider.summary)
                                            .font(.caption)
                                            .foregroundStyle(Color.white.opacity(0.66))
                                    }
                                    Spacer()
                                    Image(systemName: provider == .cloudKit ? "arrow.triangle.2.circlepath.icloud.fill" : "externaldrive.fill.badge.icloud")
                                        .foregroundStyle(GoldStudioTheme.sparkle)
                                }
                                .padding(14)
                                .goldPanel()
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("Latest Status")
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settings.lastBackupProvider.isEmpty ? "Awaiting first checkpoint" : settings.lastBackupProvider)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(settings.backupStatusMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.white.opacity(0.66))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .goldPanel()

                        if let lastBackupAt = settings.lastBackupAt {
                            Text("Last backup: \(lastBackupAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(Color.white.opacity(0.58))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("Backup Timeline")

                    if snapshots.isEmpty {
                        Text("No backup checkpoints recorded yet.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.62))
                            .padding(16)
                            .goldPanel()
                    } else {
                        ForEach(snapshots.prefix(8)) { snapshot in
                            HStack(spacing: 12) {
                                Image(systemName: snapshot.provider == BackupProvider.cloudKit.rawValue ? "icloud.fill" : "externaldrive.fill.badge.icloud")
                                    .foregroundStyle(GoldStudioTheme.sparkle)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(snapshot.provider) • \(snapshot.status)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text("\(snapshot.sessionCount) sessions • \(snapshot.favoriteCount) favorites")
                                        .font(.caption)
                                        .foregroundStyle(Color.white.opacity(0.62))
                                }

                                Spacer()

                                Text(snapshot.createdAt.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(Color.white.opacity(0.45))
                            }
                            .padding(14)
                            .goldPanel()
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var backupHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cloud Continuity")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(GoldStudioTheme.sparkle)
            Text("CloudKit is the live sync path, and iCloud recovery checkpoints keep backup intent visible inside the studio.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.72))
        }
        .padding(18)
        .goldPanel()
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.92))
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.62))
            }
        }
        .tint(Color(red: 0.91, green: 0.74, blue: 0.32))
    }
}
