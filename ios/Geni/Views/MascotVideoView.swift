import AVFoundation
import SwiftUI
import UIKit

/// Bundled mascot clips: transparent HEVC, 30 fps, each starting and ending on the `HeroMascot` pose.
enum MascotClip: String {
    case hello = "mascot_hello"
    case idle = "mascot_idle"
    case cheer = "mascot_cheer"

    var url: URL? { Bundle.main.url(forResource: rawValue, withExtension: "mov") }
}

/// Geni's 3D animation: waves hello, then idles in a seamless loop; bump `cheers` to make it cheer once.
/// The clips are transparent HEVC (`Resources/Mascot`) whose boundary frames all match the idle pose,
/// which is also the `HeroMascot` still. Without the clips it simply shows that still.
struct MascotVideoView: UIViewRepresentable {
    /// Width / height of the clips and of `HeroMascot`.
    static let aspectRatio: CGFloat = 794.0 / 934.0

    /// Played once before the idle loop; nil starts straight in the idle loop.
    var intro: MascotClip? = .hello
    /// Bump to play the cheer.
    var cheers = 0

    func makeUIView(context: Context) -> MascotPlayerView {
        let view = MascotPlayerView()
        view.intro = intro
        view.cheers = cheers
        return view
    }

    func updateUIView(_ view: MascotPlayerView, context: Context) {
        guard view.cheers != cheers else { return }
        view.cheers = cheers
        view.cheer()
    }

    static func dismantleUIView(_ view: MascotPlayerView, coordinator: ()) {
        view.tearDown()
    }
}

final class MascotPlayerView: UIView {
    /// Hosts the AVPlayerLayer above the poster.
    private final class LayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    }

    /// Clips play at most this much faster while hurrying to their neutral last frame before a cheer.
    private static let maxHurryRate: Float = 4
    /// A tap gets its cheer within about this many seconds.
    private static let hurryTarget = 0.5
    /// Seconds around every clip boundary where the poster (the neutral pose every clip starts and ends on)
    /// sits under the video, hiding the empty frame AVPlayerLayer occasionally shows between queued items.
    private static let coverBeforeEnd = 0.07
    private static let coverAfterStart = 0.1

    var cheers = 0
    var intro: MascotClip? = .hello

    private let poster = UIImageView(image: UIImage(named: "HeroMascot"))
    private let videoView = LayerView()
    private var player: AVQueuePlayer?
    private var assets: [MascotClip: AVURLAsset] = [:]
    private var cheerItem: AVPlayerItem?
    private var hasPlayedIntro = false
    private var isReadyForDisplay = false
    private var readyObservation: NSKeyValueObservation?
    private var timeObserver: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isAccessibilityElement = false
        for view in [poster, videoView] as [UIView] {
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.backgroundColor = .clear
            view.isOpaque = false
            addSubview(view)
        }
        poster.contentMode = .scaleAspectFit
        videoView.playerLayer?.videoGravity = .resizeAspect
        // Keep the alpha channel; the default pixel format drops it and draws a black box.
        videoView.playerLayer?.pixelBufferAttributes = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        NotificationCenter.default.addObserver(
            self, selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { tearDown() } else { start() }
    }

    /// The intro clip (first appearance only), then the idle loop.
    private func start() {
        guard player == nil, let idle = item(.idle), let nextIdle = item(.idle) else { return }
        var items = [idle, nextIdle]
        if !hasPlayedIntro, let intro, let first = item(intro) { items.insert(first, at: 0) }
        hasPlayedIntro = true

        let player = AVQueuePlayer(items: items)
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        player.automaticallyWaitsToMinimizeStalling = false
        videoView.playerLayer?.player = player
        self.player = player

        readyObservation = videoView.playerLayer?.observe(\.isReadyForDisplay, options: [.initial, .new]) { layer, _ in
            let ready = layer.isReadyForDisplay
            DispatchQueue.main.async { [weak self] in
                self?.isReadyForDisplay = ready
                self?.tick()
            }
        }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 30), queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        if UIApplication.shared.applicationState != .background { player.play() }
    }

    /// Cheers once the current clip reaches its neutral last frame, hurrying it there so the tap feels instant
    /// without a pose jump. Taps during a cheer are ignored.
    func cheer() {
        guard let player, let current = player.currentItem, cheerItem == nil, let cheer = item(.cheer) else { return }
        for queued in player.items().dropFirst() { player.remove(queued) }
        player.insert(cheer, after: current)
        if let idle = item(.idle) { player.insert(idle, after: cheer) }
        cheerItem = cheer

        let remaining = current.duration.seconds - current.currentTime().seconds
        guard remaining.isFinite, remaining > Self.hurryTarget, player.rate > 0 else { return }
        let limit = current.canPlayFastForward ? Self.maxHurryRate : 2
        player.rate = min(limit, Float(remaining / Self.hurryTarget))
    }

    /// Every frame: covers clip boundaries with the poster, ends a hurry before the next clip starts, keeps the queue fed.
    private func tick() {
        guard let player, let item = player.currentItem else { return }
        let elapsed = item.currentTime().seconds
        let remaining = item.duration.seconds - elapsed
        let nearEnd = remaining.isFinite && remaining < Self.coverBeforeEnd
        let atBoundary = elapsed < Self.coverAfterStart || nearEnd
        let hidePoster = isReadyForDisplay && !atBoundary
        if poster.isHidden != hidePoster { poster.isHidden = hidePoster }

        if player.rate > 1, item === cheerItem || remaining < Self.coverBeforeEnd * 2 { player.rate = 1 }
        if let cheerItem, !player.items().contains(cheerItem) { self.cheerItem = nil }
        // Keep one idle item queued behind the current clip so the loop never runs dry.
        if player.items().count < 2, let idle = self.item(.idle) { player.insert(idle, after: nil) }
    }

    private func item(_ clip: MascotClip) -> AVPlayerItem? {
        if let asset = assets[clip] { return AVPlayerItem(asset: asset) }
        guard let url = clip.url else { return nil }
        let asset = AVURLAsset(url: url)
        assets[clip] = asset
        return AVPlayerItem(asset: asset)
    }

    @objc private func didEnterBackground() {
        player?.pause()
    }

    @objc private func willEnterForeground() {
        guard window != nil else { return }
        player?.play()
    }

    /// Releases the player and decoders; the poster stays visible.
    func tearDown() {
        player?.pause()
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        timeObserver = nil
        readyObservation = nil
        isReadyForDisplay = false
        videoView.playerLayer?.player = nil
        player?.removeAllItems()
        player = nil
        cheerItem = nil
        assets = [:]
        poster.isHidden = false
    }
}
