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
    @ObservedObject var blemanager : BluetoothManager
//    @ObservedObject var cameraPeripheral: CameraPeripheral

    var body: some View{
        HomeView(model: HomeStore(), blemanager: BluetoothManager())
    }
    
}

struct HomeView_Previews: PreviewProvider{
    static var previews: some View{
        ContentView(model:HomeStore(), blemanager: BluetoothManager())
    }
}

struct AddView: View {
    var body: some View {
        Text("Add View")
    }
}
