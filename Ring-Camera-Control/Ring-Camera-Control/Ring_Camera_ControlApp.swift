//
//  Ring_Camera_ControlApp.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import StoreKit
import MediaPlayer

@main
struct Ring_Camera_ControlApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var homeModel: HomeStore = HomeStore()
    @StateObject var bleManager: BluetoothManager = BluetoothManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase, perform: { value in
                    if value == .active {
                        updateSongs()
                    }
                })
        }.modelContainer(for: HomeEmbeddings.self)
    }
    
    func updateSongs() {
        SKCloudServiceController.requestAuthorization{ status in
            if status == .authorized {
                print("skcloud service good:)")
                let songsQuery = MPMediaQuery.songs()
                if let songs = songsQuery.items {
                    let desc = NSSortDescriptor(key: MPMediaItemPropertyLastPlayedDate, ascending: false)
                    let sortedSongs = NSArray(array: songs).sortedArray(using: [desc])

                    MusicModel.shared.librarySongs = sortedSongs as! [MPMediaItem]
                }

                let playlistQuery = MPMediaQuery.playlists()
                if let playlists = playlistQuery.collections {
                    MusicModel.shared.playlist = playlists
                }
            }
        }
    }
}
