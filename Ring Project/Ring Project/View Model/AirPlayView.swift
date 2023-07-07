// I need to use AVRoutePicker to choose device to play media
// Try supporting remote controls for background running
// To do so, Become a Now Playing App by adding remote controls and activating non-mixabe AVAudioSession .playback
// MPNowPlayingInfoCenter.playbackState for MacOS
// AVPlayerViewController handles remote conrtols


// For now DO NOT USE
import SwiftUI
import MediaPlayer

struct AirPlayView: UIViewRepresentable {
    func makeUIView(context: Context) -> some UIView {
        let routePickerView = MPVolumeView()
        routePickerView.showsVolumeSlider = false
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // no update code needed
    }
}
