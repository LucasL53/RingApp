//
//  Model.swift
//  MediaPlayerTest
//
//  Created by Yunseo Lee on 10/1/23.
//

import Foundation
import MediaPlayer
import SwiftUI

class MusicModel: ObservableObject {
    
    static let shared = MusicModel()
    
    var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    @Published var currentSong: MPMediaItem?
    @Published var isPlayerViewPresented = false
    
    @Published var playlist = [MPMediaItemCollection]()
    @Published var librarySongs = [MPMediaItem]()
    
    func resumePlayback() {
            if let lastPlayedItem = musicPlayer.nowPlayingItem {
                // Update the current song property
                musicPlayer.setQueue(with: MPMediaItemCollection(items: [lastPlayedItem]))
                
                // Start playback if a track is available
                musicPlayer.play()
            } else {
                // If there's no last played item, play the first song in librarySongs
                guard !librarySongs.isEmpty else {
                    // Optionally, handle the case where librarySongs is empty
                    return
                }
                let firstSong = librarySongs[0]
                musicPlayer.setQueue(with: MPMediaItemCollection(items: [firstSong]))
                musicPlayer.play()
            }
        }
    func pause() {
        musicPlayer.pause()
    }
}
