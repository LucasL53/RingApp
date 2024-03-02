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
        if musicPlayer.playbackState == .paused {
            // Simply resume playback
            musicPlayer.play()
            return // Exit the function early as we don't need to change the queue
        }
        
        if let lastPlayedItem = musicPlayer.nowPlayingItem {
            // Update the current song property
            print("Last played: \(lastPlayedItem.title!)")
            musicPlayer.setQueue(with: MPMediaItemCollection(items: [lastPlayedItem]))
            
            // Start playback if a track is available
            musicPlayer.play()
        } else {
            // If there's no last played item, play the first song in librarySongs
            guard !librarySongs.isEmpty else {
                // Optionally, handle the case where librarySongs is empty
                print("No songs in library")
                return
            }
            let firstSong = librarySongs[0]
            print("Queueing \(firstSong.title!)")
            musicPlayer.setQueue(with: MPMediaItemCollection(items: [firstSong]))
            musicPlayer.play()
        }
    }
    
    func pause() {
        musicPlayer.pause()
    }
}
