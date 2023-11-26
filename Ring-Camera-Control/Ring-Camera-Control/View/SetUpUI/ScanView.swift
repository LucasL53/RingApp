//
//  ScanView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 11/23/23.
//

import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) var modelContext
    
    @Bindable var accessoryEmbedding: AccessoryEmbedding
    
    @StateObject var blemanager = BluetoothManager()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(accessoryEmbedding.photoAndEmbeddings, id: \.self) { photoAndEmbedding in
                    if let photoData = photoAndEmbedding.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                }
            }
        }.onAppear(perform: {
            blemanager.scanStatus = true
        })
        .onDisappear(perform: {
            blemanager.scanStatus = false
        })
    }
}
