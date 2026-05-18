// © 2026 World Class Scholars — Dr. Christopher Appiah-Thompson. All Rights Reserved.
// Ethereal Veil™ is a trademark of World Class Scholars.
// Unauthorized reproduction or distribution is prohibited.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DrawingSession.updatedAt, order: .reverse) private var sessions: [DrawingSession]
    @Query(sort: \FavoriteTrack.addedAt, order: .reverse) private var favoriteTracks: [FavoriteTrack]
    @Query(sort: \BackupSnapshot.createdAt, order: .reverse) private var backupSnapshots: [BackupSnapshot]
    @Query private var settingsRecords: [AppSettings]

    @State private var musicPlayer = MusicPlayer()
    @State private var accessManager = AccessControlManager()
    @State private var paymentManager = PaymentManager()
    @State private var selectedTab: StudioTab = .draw
    @State private var showPlaylist = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var statusMessage = "Cloud-connected studio ready."

    var body: some View {
        NavigationStack {
            ZStack {
                GoldStudioTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    heroHeader
                    workspaceContainer
                    musicStrip
                    tabBar
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .preferredColorScheme(.dark)
            .task {
                await prepareStudio()
            }
            .sheet(isPresented: $accessManager.showPaywall) {
                PaywallSheet(access: accessManager, payments: paymentManager)
            }
            .sheet(isPresented: $showPlaylist) {
                PlaylistSheet(
                    player: musicPlayer,
                    favoriteTrackIDs: favoriteTrackIDs,
                    onToggleFavorite: toggleFavorite
                )
            }
            .alert("Unable to complete action", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .onChange(of: selectedTab) { _, tab in
            gateTabSelection(tab)
            if tab == .draw || tab == .paint,
               !musicPlayer.isPlaying,
               currentSettings?.autoPlayMusic == true,
               musicPlayer.tracks.contains(where: { $0.audioURL != nil }) {
                musicPlayer.togglePlayPause()
            }
        }
    }

    private var currentSettings: AppSettings? {
        settingsRecords.first
    }

    private var favoriteTrackIDs: Set<String> {
        Set(favoriteTracks.map(\.filename))
    }

    private var backupSummaryText: String {
        if let settings = currentSettings {
            return settings.backupStatusMessage
        }

        return "Preparing CloudKit and iCloud backup settings."
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ethereal Veil")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(GoldStudioTheme.sparkle)
                    Text("Highly polished spackled gold controls for drawing, painting, saved studio routes, and cloud continuity.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.72))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(accessManager.accessBadge)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(GoldStudioTheme.sparkle))
                    Text(backupSummaryText)
                        .font(.caption)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Color.white.opacity(0.6))
                        .frame(maxWidth: 200)
                }
            }

            HStack(spacing: 10) {
                heroActionButton(title: "Playlist", icon: "music.note.list") {
                    showPlaylist = true
                }
                heroActionButton(title: "Library", icon: "books.vertical.fill") {
                    selectedTab = .library
                }
                heroActionButton(title: "Backup", icon: "icloud.and.arrow.up.fill") {
                    openTab(.cloud)
                }
                heroActionButton(title: "Account", icon: "person.crop.circle.fill") {
                    selectedTab = .account
                }
            }

            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.68))
        }
        .padding(18)
        .goldPanel()
    }

    private var workspaceContainer: some View {
        Group {
            switch selectedTab {
            case .draw:
                DrawingTab(
                    musicPlayer: musicPlayer,
                    onSave: { saveSession(kind: .drawing, strokeCount: $0) },
                    onOpenLibrary: { openTab(.library) },
                    onOpenPlaylist: { showPlaylist = true },
                    onOpenCloud: { openTab(.cloud) }
                )
            case .paint:
                if accessManager.canAccess(.paint, sessionCount: sessions.count) {
                    PaintingTab(
                        musicPlayer: musicPlayer,
                        onSave: { saveSession(kind: .painting, strokeCount: $0) },
                        onOpenLibrary: { openTab(.library) },
                        onOpenPlaylist: { showPlaylist = true },
                        onOpenCloud: { openTab(.cloud) }
                    )
                } else {
                    premiumLockedPanel(feature: .paint)
                }
            case .library:
                SessionLibraryView(
                    sessions: sessions,
                    favorites: favoriteTracks,
                    onSelectTab: { selectedTab = $0 }
                )
            case .cloud:
                if accessManager.canAccess(.cloudBackup, sessionCount: sessions.count) {
                    CloudBackupView(
                        settings: currentSettings,
                        snapshots: backupSnapshots,
                        sessionCount: sessions.count,
                        favoriteCount: favoriteTracks.count,
                        onCloudKitToggle: { updateBackups(cloudKitEnabled: $0, iCloudEnabled: nil) },
                        onICloudToggle: { updateBackups(cloudKitEnabled: nil, iCloudEnabled: $0) },
                        onBackup: recordBackup
                    )
                } else {
                    premiumLockedPanel(feature: .cloudBackup)
                }
            case .account:
                AccountAccessView(access: accessManager, payments: paymentManager)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(GoldStudioTheme.sparkle.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Music Strip

    private var musicStrip: some View {
        HStack(spacing: 12) {
            // Animated waveform indicator
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { barIndex in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(GoldStudioTheme.sparkle)
                        .frame(width: 3, height: musicPlayer.isPlaying ? CGFloat.random(in: 6...16) : 4)
                        .animation(
                            musicPlayer.isPlaying
                                ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(barIndex) * 0.1)
                                : .default,
                            value: musicPlayer.isPlaying
                        )
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(musicPlayer.currentTrack.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(musicPlayer.currentTrack.composer)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            // Progress arc
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: musicPlayer.progress)
                    .stroke(GoldStudioTheme.sparkle, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 22, height: 22)

            Button { musicPlayer.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button { musicPlayer.togglePlayPause() } label: {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle().fill(GoldStudioTheme.sparkle).shadow(color: Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.5), radius: 8)
                    )
            }

            Button { musicPlayer.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Button(action: toggleFavoriteCurrentTrack) {
                Image(systemName: favoriteTrackIDs.contains(StudioStore.trackIdentifier(for: musicPlayer.currentTrack)) ? "heart.fill" : "heart")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(GoldStudioTheme.sparkle)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .goldPanel()
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(StudioTab.allCases) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .goldPanel()
    }

    private func premiumLockedPanel(feature: StudioFeature) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundStyle(GoldStudioTheme.sparkle)
            Text("\(feature.title) requires Studio Pro")
                .font(.headline)
                .foregroundStyle(.white)
            Button("View plans") {
                accessManager.paywallFeature = feature
                accessManager.showPaywall = true
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(GoldStudioTheme.sparkle))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openTab(_ tab: StudioTab) {
        accessManager.requestAccess(
            to: tab == .paint ? .paint : (tab == .cloud ? .cloudBackup : .librarySave),
            sessionCount: sessions.count
        ) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        }
    }

    private func gateTabSelection(_ tab: StudioTab) {
        switch tab {
        case .paint:
            if !accessManager.canAccess(.paint, sessionCount: sessions.count) {
                selectedTab = .draw
                accessManager.paywallFeature = .paint
                accessManager.showPaywall = true
            }
        case .cloud:
            if !accessManager.canAccess(.cloudBackup, sessionCount: sessions.count) {
                selectedTab = .draw
                accessManager.paywallFeature = .cloudBackup
                accessManager.showPaywall = true
            }
        default:
            break
        }
    }

    private func tabButton(tab: StudioTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(GoldStudioTheme.sparkle)
                            .frame(width: 42, height: 42)
                            .shadow(color: Color(red: 0.88, green: 0.69, blue: 0.29).opacity(0.6), radius: 12)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                        .foregroundStyle(selectedTab == tab ? .black : .white.opacity(0.4))
                }
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func heroActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Capsule().fill(GoldStudioTheme.sparkle))
        }
        .buttonStyle(.plain)
    }

    private func prepareStudio() async {
        do {
            _ = try StudioStore.ensureSettings(in: modelContext)
            try accessManager.bootstrap(in: modelContext)
            await paymentManager.loadProducts()
            try? await accessManager.syncSubscription(paymentManager: paymentManager, in: modelContext)
        } catch {
            present(error)
        }
    }

    private func saveSession(kind: StudioSaveKind, strokeCount: Int) {
        guard strokeCount > 0 else {
            statusMessage = "Add a few strokes before saving a session."
            return
        }

        guard accessManager.canAccess(.librarySave, sessionCount: sessions.count) else {
            accessManager.paywallFeature = .librarySave
            accessManager.showPaywall = true
            statusMessage = "Free tier allows \(3) saved sessions. Upgrade for unlimited saves."
            return
        }

        do {
            let settings = try StudioStore.ensureSettings(in: modelContext)
            let session = try StudioStore.saveSession(kind: kind, strokeCount: strokeCount, in: modelContext)
            statusMessage = "\(session.title) saved to the library."
            selectedTab = .library

            if settings.cloudKitSyncEnabled {
                try StudioStore.recordBackup(
                    provider: .cloudKit,
                    settings: settings,
                    sessionCount: sessions.count,
                    favoriteCount: favoriteTracks.count,
                    in: modelContext
                )
            }
        } catch {
            present(error)
        }
    }

    private func toggleFavorite(_ track: MusicTrack) {
        do {
            let isFavorite = try StudioStore.toggleFavorite(track: track, in: modelContext)
            statusMessage = isFavorite ? "\(track.title) added to favorites." : "\(track.title) removed from favorites."
        } catch {
            present(error)
        }
    }

    private func toggleFavoriteCurrentTrack() {
        toggleFavorite(musicPlayer.currentTrack)
    }

    private func updateBackups(cloudKitEnabled: Bool?, iCloudEnabled: Bool?) {
        do {
            let settings = try StudioStore.ensureSettings(in: modelContext)
            try StudioStore.updateBackupPreferences(
                settings: settings,
                cloudKitSyncEnabled: cloudKitEnabled,
                iCloudBackupEnabled: iCloudEnabled,
                in: modelContext
            )
            statusMessage = settings.backupStatusMessage
        } catch {
            present(error)
        }
    }

    private func recordBackup(_ provider: BackupProvider) {
        do {
            let settings = try StudioStore.ensureSettings(in: modelContext)
            try StudioStore.recordBackup(
                provider: provider,
                settings: settings,
                sessionCount: sessions.count,
                favoriteCount: favoriteTracks.count,
                in: modelContext
            )
            statusMessage = "\(provider.label) checkpoint recorded."
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

#Preview { ContentView() }
