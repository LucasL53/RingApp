//
//  HomeView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 5/19/23.
//

import SwiftUI
import HomeKit

struct HomeView: View {
    
    @State private var path = NavigationPath()
    @ObservedObject var model: HomeStore
    @ObservedObject var blemanager: BluetoothManager
    
    var body: some View {
        NavigationStack(path: $path) {
                    List {
                        Section(header: HStack {
                            Text("My Homes")
                        }) {
                            ForEach(model.homes, id: \.uniqueIdentifier) { home in
                                NavigationLink(value: home){
                                    Text("\(home.name)")
                                }.navigationDestination(for: HMHome.self){
                                    AccessoriesView(homeId: $0.uniqueIdentifier, model: model, blemanager: blemanager)
                                }
                            }
                        }
                    }
                }
    }
}
