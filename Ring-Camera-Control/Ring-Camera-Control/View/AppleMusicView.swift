//
//  AppleMusicView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 9/24/23.
//

import SwiftUI
import MusicKit

class MusicPlayer: ObservableObject {
    
}

struct AppleMusicView: View {
    @State private var searchText = ""
    @State private var searchResults: [Song] = []
    @StateObject private var musicPlayer = MusicPlayer()
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonChanged: searchMusic)
                List($searchResults, id: \.id) { song in
                    SongRow
                }
            }
            .navigationTitle("SwiftMusicKit")
        }
        .environmentObject(musicPlayer)
    }
    
    private func searchMusic() {
        // MusicKit search logic here
        // Update searchResults array
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonChanged: () -> Void
    
    var body: some View {
        TextField("Search", text: $text, onCommit: {
            onSearchButtonChanged()
        })
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
    }
}
