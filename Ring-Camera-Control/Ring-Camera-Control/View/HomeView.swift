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
    
    @Environment(\.modelContext) var modelContext
    
    @State var showCreate = false
    @State private var selectedHomeId: UUID?
    @State private var selectedHomeEmbedding: HomeEmbeddings?
    @State var header: String?
    
    @ObservedObject var model: HomeStore
    
    @Query var embeddings: [HomeEmbeddings]
    
    var body: some View {
        VStack {
            Menu(header ?? "Select Home") {
                ForEach(model.homes, id: \.uniqueIdentifier) { home in
                    Button(action: {
                        selectedHomeId = home.uniqueIdentifier
                        header = "\(home.name)"
                        model.findAccessories(homeId: selectedHomeId!)
                        if let embedding = embeddings.first(where: {$0.home == header!}) {
                            selectedHomeEmbedding = embedding
                        } else {
                            print("no home embedding found")
                        }
                        print("changed")
                    }) {
                        Text("\(home.name)")
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        showCreate.toggle()
                    }, label: {
                        Label("Scan Accessories", systemImage: "plus")
                    })
                }
            }
            .sheet(isPresented: $showCreate,
                   content: {
                NavigationStack{
                    SetUpView(home: embeddings.first(where: { $0.home == header })!)
                }
                .presentationDetents([.large])
            })
            
            Spacer()
            
            // Rest of the content
            if selectedHomeId != nil,
                let _ = model.homes.first(where: { $0.uniqueIdentifier == selectedHomeId }) {
                ControlView(homeId: $selectedHomeId, homeEmbedding: $selectedHomeEmbedding, model: model)
            }
        }
        .onChange(of: model.areHomesLoaded) {
            if model.areHomesLoaded {
                initializeNewHomes()
                if let primaryHome = model.homes.first {
                    selectedHomeId = primaryHome.uniqueIdentifier
                    header = primaryHome.name
                    model.areHomesLoaded = false
                    model.findAccessories(homeId: selectedHomeId!)
                }
                initializeAccessories(currHome: header!)
            }
        }
        .onChange(of: header) {
            if let homeId = selectedHomeId {
                model.findAccessories(homeId: homeId)
                if let homeName = header {
                    initializeAccessories(currHome: homeName)
                } else {
                    print("Can't read home name")
                }
            } else {
                print("No home UUID found")
            }
            
        }
    }
    
    func initializeNewHomes() {
        print("Ran init Home embeddings")
        for home in model.homes {
            if !embeddings.contains(where: {$0.home == home.name}) {
                let accessoryEmbeddings: [AccessoryEmbedding] = []
                let newEmbedding = HomeEmbeddings(home: home.name, accessoryembeddings: accessoryEmbeddings)
                modelContext.insert(newEmbedding)
            }
        }
    }
    
    // Populate all the accessory information needed for AccessoryEmbedding of selectedHome.
    func initializeAccessories(currHome: String) {
        print("Running Init Accessory Embeddings")
        if let embedding = embeddings.first(where: {$0.home == currHome}) {
            if embedding.isPopulated(size: model.accessories.count) { // TODO: Can be optimized
                print("No further population needed")
            } else {
                for accessory in model.accessories {
                    if !embedding.hasAccessory(accessoryName: accessory.name){
                        let newAccessory = AccessoryEmbedding(accessoryUUID: accessory.uniqueIdentifier, accessoryName: accessory.name)
                        // Does this save?
                        embedding.accessoryembeddings.append(newAccessory)
                    } else {
                        print("already added accessory")
                    }
                }
            }
            embedding.printOut()
        }
    }
}
