//
//  MusicPlayer.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/29/23.
//
import SwiftUI
import MusicKit
import MediaPlayer

struct AppleMusicPlayer: View {
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            Image(systemName: "play.fill")
                .font(.title)
                .onTapGesture {
                    MusicModel().resumePlayback()
                }
                .disabled(isPlaying)
        }
    }
    
    
}
