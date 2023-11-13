//
//  HomeView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import HomeKit
import SwiftData

struct HomeView: View {
    
    @State private var selectedHomeId: UUID?
    @ObservedObject var model: HomeStore
    @State var header: String?
    
    @Query var embeddings: [HomeEmbeddings]
    
    var body: some View {
        VStack {
            // Menu as the sticky header
            Menu(header ?? "Select Home") {
                ForEach(model.homes, id: \.uniqueIdentifier) { home in
                    Button(action: {
                        selectedHomeId = home.uniqueIdentifier
                        header = "\(home.name)"
                        model.findAccessories(homeId: selectedHomeId!)
                        print("changed")
                    }) {
                        Text("\(home.name)")
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Spacer()
            
            // Rest of the content
            if selectedHomeId != nil,
                let _ = model.homes.first(where: { $0.uniqueIdentifier == selectedHomeId }) {
                ControlView(homeId: $selectedHomeId, model: model)
            }
        }
        .onChange(of: model.areHomesLoaded) {
            if model.areHomesLoaded {
                if let primaryHome = model.homes.first {
                    selectedHomeId = primaryHome.uniqueIdentifier
                    header = primaryHome.name
                    model.areHomesLoaded = false
                    model.findAccessories(homeId: selectedHomeId!)
                }
            }
        }
    }
    
    func initializeAccessories() {
        if let embedding = embeddings.first(where: {$0.home == header}) {
            for accessory in model.accessories {
                if !embedding.hasAccessory(accessoryName: accessory.name){
                    let newAccessory = AccessoryEmbedding(accessoryUUID: accessory.uniqueIdentifier, accessoryName: accessory.name)
                    // Does this save?
                    embedding.accessoryembeddings.append(newAccessory)
                }
            }
        }
    }
}
