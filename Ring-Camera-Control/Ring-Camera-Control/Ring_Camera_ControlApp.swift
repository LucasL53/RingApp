//
//  Ring_Camera_ControlApp.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI

@main
struct Ring_Camera_ControlApp: App {
    @StateObject var homeModel: HomeStore = HomeStore()
    @StateObject var bleManager: BluetoothManager = BluetoothManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
