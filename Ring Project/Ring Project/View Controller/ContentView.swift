//
//  ContentView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 5/1/23.
//

import SwiftUI
import HomeKit

struct ContentView: View {
    @State private var path = NavigationPath()
    @ObservedObject var model: HomeStore

    var body: some View{
        HomeView(model: HomeStore())
        
    }
    
}

struct HomeView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView(model:HomeStore())
    }
}

struct AddView: View {
    var body: some View {
        Text("Add View")
    }
}
