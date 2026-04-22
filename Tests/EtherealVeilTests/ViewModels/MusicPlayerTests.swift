// © World Class Scholars 2026 - Dr. Christopher Appiah-Thompson
// MusicPlayer tests — playlist, navigation, state, edge cases.

import XCTest
@testable import EtherealVeil

@MainActor
final class MusicPlayerTests: XCTestCase {

    private var sut: MusicPlayer!

    override func setUp() {
        super.setUp()
        sut = MusicPlayer()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func testInitialIndexIsZero() {
        XCTAssertEqual(sut.currentIndex, 0)
    }

    func testInitialIsPlayingFalse() {
        XCTAssertFalse(sut.isPlaying)
    }

    func testInitialProgressIsZero() {
        XCTAssertEqual(sut.progress, 0)
    }

    func testPlaylistIsNotEmpty() {
        XCTAssertFalse(sut.tracks.isEmpty)
    }

    func testPlaylistHasExpectedCount() {
        XCTAssertEqual(sut.tracks.count, 9)
    }

    // MARK: - Track properties

    func testAllTracksHaveTitles() {
        sut.tracks.forEach { XCTAssertFalse($0.title.isEmpty, "Track has empty title") }
    }

    func testAllTracksHaveComposers() {
        sut.tracks.forEach { XCTAssertFalse($0.composer.isEmpty, "Track has empty composer") }
    }

    func testAllTracksHaveDurationLabel() {
        sut.tracks.forEach {
            XCTAssertTrue($0.durationLabel.contains(":"), "\($0.title) duration label malformed")
        }
    }

    func testAllTracksHaveUniqueIDs() {
        let ids = sut.tracks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    // MARK: - Navigation

    func testNextAdvancesIndex() {
        let initial = sut.currentIndex
        sut.next()
        XCTAssertEqual(sut.currentIndex, initial + 1)
    }

    func testNextWrapsAroundAtEnd() {
        sut.play(index: sut.tracks.count - 1)
        sut.next()
        XCTAssertEqual(sut.currentIndex, 0)
    }

    func testPreviousDecrementsIndex() {
        sut.play(index: 3)
        sut.previous()
        XCTAssertEqual(sut.currentIndex, 2)
    }

    func testPreviousWrapsAroundAtStart() {
        sut.play(index: 0)
        sut.previous()
        XCTAssertEqual(sut.currentIndex, sut.tracks.count - 1)
    }

    func testPlaySpecificIndex() {
        sut.play(index: 4)
        XCTAssertEqual(sut.currentIndex, 4)
    }

    func testPlayOutOfBoundsIsHarmless() {
        let before = sut.currentIndex
        sut.play(index: 999)
        XCTAssertEqual(sut.currentIndex, before)
    }

    func testPlayNegativeIndexIsHarmless() {
        let before = sut.currentIndex
        sut.play(index: -1)
        XCTAssertEqual(sut.currentIndex, before)
    }

    // MARK: - Stop

    func testStopResetsState() {
        sut.stop()
        XCTAssertFalse(sut.isPlaying)
        XCTAssertEqual(sut.progress, 0)
    }

    // MARK: - Favorites

    func testToggleFavoriteSetsFavorite() {
        sut.toggleFavorite(at: 0)
        XCTAssertTrue(sut.tracks[0].isFavorite)
    }

    func testToggleFavoriteUnsetsFavorite() {
        sut.toggleFavorite(at: 0)
        sut.toggleFavorite(at: 0)
        XCTAssertFalse(sut.tracks[0].isFavorite)
    }

    // MARK: - Current track

    func testCurrentTrackMatchesCurrentIndex() {
        sut.play(index: 2)
        XCTAssertEqual(sut.currentTrack.id, sut.tracks[2].id)
    }

    // MARK: - Time formatting

    func testFormatZero() {
        XCTAssertEqual(sut.elapsedFormatted, "0:00")
    }

    // MARK: - Seek

    func testSeekWithNoPlayerIsHarmless() {
        XCTAssertNoThrow(sut.seek(to: 0.5))
    }

    func testSeekWithZeroDurationIsHarmless() {
        XCTAssertNoThrow(sut.seek(to: 1.0))
    }

    // MARK: - Audio URLs

    func testAllTracksHaveAudioURLs() {
        let withURL = sut.tracks.filter { $0.audioURL != nil }
        XCTAssertEqual(withURL.count, sut.tracks.count,
            "Every track should have an audio URL")
    }

    func testAudioURLsAreHTTPS() {
        for track in sut.tracks {
            if let url = track.audioURL {
                XCTAssertEqual(url.scheme, "https", "\(track.title) audio URL is not HTTPS")
            }
        }
    }

    func testAudioURLsAreMp3() {
        for track in sut.tracks {
            if let url = track.audioURL {
                XCTAssertTrue(url.pathExtension == "mp3",
                    "\(track.title) should use MP3 format for AVPlayer compatibility")
            }
        }
    }
}
