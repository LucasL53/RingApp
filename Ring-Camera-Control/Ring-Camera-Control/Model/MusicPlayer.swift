//
//  MusicPlayer.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/29/23.
//
import SwiftUI
import MusicKit

struct MusicPlayer: View {
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            Button("Play Recently Played Music") {
                fetchAndPlayRecentlyPlayedMusic()
            }
            .disabled(isPlaying)
        }
    }
    
    func fetchAndPlayRecentlyPlayedMusic() {
        // Request authorization to access Apple Music
            // Perform the request
            Task {
                let status = await MusicAuthorization.request()
                switch status {
                case .authorized:
                    // Create a request for recently played music
                    let recentlyPlayedRequest = MusicRecentlyPlayedRequest<Track>()
                    do {
                        let response = try await recentlyPlayedRequest.response()
                        
                        // Get the first recently played item (if available)
                        if let firstRecentlyPlayedItem = response.items.first {
                            
                            // Initialize the SystemMusicPlayer
                            let systemMusicPlayer = SystemMusicPlayer.shared
                            
                            // Set the queue to the system music player
                            try await systemMusicPlayer.queue.insert(firstRecentlyPlayedItem, position: .afterCurrentEntry)
                            
                            // Play the music
                            try await systemMusicPlayer.play()
                            
                            // Update UI state
                            isPlaying = true
                            
                        } else {
                            print("No recently played items found.")
                        }
                        
                    } catch {
                        print("An error occurred: \(error)")
                    }
                default:
                    print("Authorization failed")
                
            }
        }
    }
}