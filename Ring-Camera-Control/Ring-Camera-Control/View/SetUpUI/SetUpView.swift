//
//  SetUpView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 11/11/23.
//

import SwiftUI
import SwiftData

struct SetUpView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var blemanager = BluetoothManager()
    
    @Bindable var home: HomeEmbeddings
    
    @State var selectedAccessory: AccessoryEmbedding?

    
    var body: some View {
        NavigationStack{
            List{
                ForEach(home.accessoryembeddings) { accessory in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(accessory.accessoryName)")
                                .font(.title)
                                .bold()
                            
                            Text("\(accessory.size()) embeddings")
                                .font(.subheadline)
                        }
                        
                        Button {
                            selectedAccessory = accessory
                            blemanager.scanFrame(accessory: selectedAccessory!)
                        } label: {
                            Image(systemName: "plus")
                                .symbolVariant(.circle.fill)
                                .foregroundStyle(accessory.isComplete() ? .green : .gray)
                                .font(.title)
                        }
                    }
                }
            }
//            .sheet(item: $selectedAccessory) {
//                selectedAccessory = nil
//            } content: { accessoryEmbedding in
//                ScanView(accessoryEmbedding: accessoryEmbedding)
//            }
            
        }
    }
}
