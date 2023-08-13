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
    @State var header = "Select Home"
    
    var body: some View {
        VStack {
            // Menu as the sticky header
            Menu(header) {
                ForEach(model.homes, id: \.uniqueIdentifier) { home in
                    Button(action: {
                        selectedHomeId = home.uniqueIdentifier
                        header = "\(home.name)"
                    }) {
                        Text("\(home.name)")
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            
            Spacer()
            
            // Rest of the content
            ScrollView {
                if let homeId = selectedHomeId,
                   let _ = model.homes.first(where: { $0.uniqueIdentifier == homeId }) {
                    ControlView(homeId: homeId, model: model)
                }
            }
        }
    }
}
