//
//  ContentView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import MusicKit
import SwiftData

struct ContentView: View {
    
    @Environment(\.modelContext) var modelContext
    
    @ObservedObject var homeModel = HomeStore()
    @Query var embeddings: [HomeEmbeddings]
    
    var body: some View {
        ZStack {
//            if embeddings.isEmpty {
//                SetUpView()
//            }
            
            HomeView(model: homeModel)
        }.onChange(of: homeModel.areHomesLoaded){
            if homeModel.areHomesLoaded {
                initializeNewHomes()
            }
        }

    }
    
    // Checks if every new "home" added to HomeKit has persistent data initialized
    func initializeNewHomes() {
        for home in homeModel.homes {
            if !embeddings.contains(where: {$0.home == home.name}) {
                var accessoryEmbeddings: [AccessoryEmbedding] = []
                for accessory in homeModel.accessories {
                    let newAccessory = AccessoryEmbedding(accessoryUUID: accessory.uniqueIdentifier, accessoryName: accessory.name)
                    accessoryEmbeddings.append(newAccessory)
                }
                let newEmbedding = HomeEmbeddings(home: home.name, accessoryembeddings: accessoryEmbeddings)
                modelContext.insert(newEmbedding)
            }
        }
    }
    
}

