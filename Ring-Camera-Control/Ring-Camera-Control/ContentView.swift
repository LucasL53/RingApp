//
//  ContentView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    @ObservedObject var homeModel = HomeStore()
    var body: some View {
        HomeView(model: homeModel)
    }
}

#Preview {
    HomeView(model: HomeStore())
}
