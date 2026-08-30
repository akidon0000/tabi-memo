import MapKit
import SwiftUI

/// MapKitのカメラが軌跡をなぞりながら飛び、写真ピンで一時停止するアプリの核となる機能。
/// カメラの見せ方・写真の見せ方・ペーシングをそれぞれ3/3/2パターン実装し、
/// この画面内でその場に切り替えて見比べられるようにしている(Settings画面には置かない)。
struct ReplayView: View {
    let trip: Trip

    var body: some View {
        if trip.locationPoints.count < 2 {
            PhotoSlideshowView(photos: trip.photos.sorted { $0.takenAt < $1.takenAt }, tripName: trip.name)
        } else {
            RouteReplayView(trip: trip)
        }
    }
}

private struct RouteReplayView: View {
    let trip: Trip

    @State private var cameraStyle: ReplayCameraStyle = .followDrone
    @State private var photoStyle: ReplayPhotoDisplayStyle = .fullScreenCutIn
    @State private var pacingStyle: ReplayPacingStyle = .timeBased
    @State private var keyframes: [ReplayKeyframe] = []

    @State private var isPlaying = false
    @State private var playbackStartDate = Date.now
    @State private var pausedElapsed: TimeInterval = 0

    private var routeCoordinates: [CLLocationCoordinate2D] {
        trip.locationPoints.sorted { $0.timestamp < $1.timestamp }.map(\.coordinate)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isPlaying)) { timeline in
            let elapsed = isPlaying ? pausedElapsed + timeline.date.timeIntervalSince(playbackStartDate) : pausedElapsed
            let sample = ReplayPlayhead.sample(keyframes: keyframes, elapsed: elapsed)

            ZStack {
                Map(position: .constant(.camera(camera(for: sample)))) {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(Color.accentColor, lineWidth: 3)
                    ForEach(trip.photos) { photo in
                        Annotation(
                            photo.takenAt.formatted(date: .omitted, time: .shortened),
                            coordinate: photo.coordinate,
                            anchor: .bottom
                        ) {
                            PhotoPinCallout(photo: photo, isEmphasized: photoStyle == .pinEmphasis && sample.photo == photo) {}
                                .allowsHitTesting(false)
                        }
                    }
                }
                .ignoresSafeArea()

                if let photo = sample.photo, photoStyle != .pinEmphasis {
                    PhotoCutInOverlay(photo: photo, style: photoStyle)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: sample.photo)
                }

                VStack {
                    Spacer()
                    controls
                }
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                styleMenu
            }
        }
        .task {
            rebuildTimeline()
            play()
        }
        .onChange(of: pacingStyle) { rebuildTimeline(); restart() }
        .onChange(of: photoStyle) { rebuildTimeline(); restart() }
    }

    private var controls: some View {
        Button(action: togglePlayback) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.title)
                .frame(width: 64, height: 64)
                .foregroundStyle(.white)
                .background(.black.opacity(0.5), in: .circle)
        }
        .padding(.bottom, 32)
    }

    private var styleMenu: some View {
        Menu {
            Picker("カメラ", selection: $cameraStyle) {
                ForEach(ReplayCameraStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            Picker("写真の見せ方", selection: $photoStyle) {
                ForEach(ReplayPhotoDisplayStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
            Picker("ペーシング", selection: $pacingStyle) {
                ForEach(ReplayPacingStyle.allCases) { style in
                    Text(style.displayName).tag(style)
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
    }

    private func camera(for sample: ReplaySample) -> MapCamera {
        MapCamera(
            centerCoordinate: sample.coordinate,
            distance: cameraStyle.distance,
            heading: cameraStyle.followsTravelHeading ? sample.heading : 0,
            pitch: cameraStyle.pitch
        )
    }

    private func rebuildTimeline() {
        keyframes = ReplayTimeline.build(trip: trip, pacing: pacingStyle, photoStyle: photoStyle)
    }

    private func restart() {
        pausedElapsed = 0
        playbackStartDate = .now
    }

    private func play() {
        playbackStartDate = .now
        isPlaying = true
    }

    private func togglePlayback() {
        if isPlaying {
            pausedElapsed += Date.now.timeIntervalSince(playbackStartDate)
            isPlaying = false
        } else {
            if pausedElapsed >= ReplayPlayhead.totalDuration(keyframes) {
                pausedElapsed = 0
            }
            playbackStartDate = .now
            isPlaying = true
        }
    }
}

/// 写真到達時のカットイン(全画面 or オーバーレイカード)。pinEmphasisのときはこのビュー自体を使わない。
private struct PhotoCutInOverlay: View {
    let photo: TripPhoto
    let style: ReplayPhotoDisplayStyle

    var body: some View {
        switch style {
        case .fullScreenCutIn:
            ZStack {
                Color.black.ignoresSafeArea()
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                }
            }
        case .overlayCard:
            VStack {
                Spacer()
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        .padding(.horizontal, 24)
                }
                Spacer().frame(height: 140)
            }
        case .pinEmphasis:
            EmptyView()
        }
    }
}

/// 位置点が2未満のトリップ向けフォールバック: カメラ移動なしで写真だけを順番にカットイン表示する。
private struct PhotoSlideshowView: View {
    let photos: [TripPhoto]
    let tripName: String

    @State private var index = 0
    @State private var isPlaying = true

    private static let holdDuration: TimeInterval = 2.2

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if photos.indices.contains(index), let uiImage = UIImage(data: photos[index].imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .id(index)
                    .transition(.opacity)
            } else {
                ContentUnavailableView(
                    "写真がありません",
                    systemImage: "photo",
                    description: Text("軌跡も写真もないためリプレイできません")
                )
                .foregroundStyle(.white)
            }

            VStack {
                Spacer()
                if photos.count > 1 {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.white)
                            .background(.black.opacity(0.5), in: .circle)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle(tripName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: isPlaying) {
            guard isPlaying, photos.count > 1 else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.holdDuration))
                if Task.isCancelled { return }
                withAnimation {
                    index = (index + 1) % photos.count
                }
            }
        }
    }
}
