//
//  Model.swift
//  MediaPlayerTest
//
//  Created by Yunseo Lee on 10/1/23.
//

import Foundation
import MediaPlayer

class MusicModel: ObservableObject {
    
    static let shared = MusicModel()
    
    var musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    
    @Published var currentSong: MPMediaItem?
    @Published var isPlayerViewPresented = false
    
    @Published var playlist = [MPMediaItemCollection]()
    @Published var librarySongs = [MPMediaItem]()
    
}
