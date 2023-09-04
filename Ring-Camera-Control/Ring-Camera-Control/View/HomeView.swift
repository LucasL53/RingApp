//
//  HomeView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import HomeKit

struct HomeView: View {
    
    @State private var selectedHomeId: UUID?
    @ObservedObject var model: HomeStore
    @State var header: String?
    
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
        .onChange(of: model.areHomesLoaded) { areLoaded in
            if areLoaded {
                if let primaryHome = model.homes.first(where: { $0.isPrimary }) {
                    selectedHomeId = primaryHome.uniqueIdentifier
                    header = primaryHome.name
                    model.areHomesLoaded = false
                }
            }
        }
    }
}
