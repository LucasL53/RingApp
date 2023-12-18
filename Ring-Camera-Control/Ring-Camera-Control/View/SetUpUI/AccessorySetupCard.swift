////
////  AccessorySetupCard.swift
////  Ring-Camera-Control
////
////  Created by Yunseo Lee on 11/23/23.
////
//
//import SwiftUI
//
//struct AccessorySetupCard: View {
//    @State private var navigateToScan = false
//    let accessoryEmbedding: AccessoryEmbedding
//    
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(accessoryEmbedding.accessoryName)
//                .font(.headline)
//                .padding()
//            if !accessoryEmbedding.isComplete() {
//                Button(action: { navigateToScan = true }) {
//                    Text("Scan Accessory")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(8)
//                }
//                .padding()
//                // Navigation to ScanView
//                NavigationLink{
//                    ScanView(accessoryEmbedding: accessoryEmbedding)
//                } label: {
//                    Label("Scan Accessory", systemImage: "plus.app")
//                }
//            } else {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(accessoryEmbedding.photoAndEmbeddings, id: \.self) { photoAndEmbedding in
//                            if let photoData = photoAndEmbedding.photo, let uiImage = UIImage(data: photoData) {
//                                Image(uiImage: uiImage)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                                    .frame(width: 100, height: 100)
//                                    .clipped()
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
