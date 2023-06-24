//
//  Ring_ProjectApp.swift
//  Ring Project
//
//  Created by Yunseo Lee on 5/1/23.
//

import SwiftUI

@main
struct Ring_ProjectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(model: HomeStore())// Fix This
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
