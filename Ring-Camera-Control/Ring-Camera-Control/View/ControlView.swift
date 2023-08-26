//
//  ControlView.swift
//  Ring-Camera-Control
//  ControlView has the main accessories of the selected Home
//  And a routerpicker to connect to Airplay2 fo TV/HomePod
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import HomeKit

struct ControlView: View {
    @State var homeId: UUID
    @ObservedObject var model: HomeStore
    @StateObject var blemanager = BluetoothManager()
    @State private var selectedAccessory: String?
    @State private var selectedAccessoryId: UUID?
    @State private var spotify: Bool = false

    var body: some View {
        VStack{
            Spacer()
            
            ScrollView {
                Section(header: Text("My Accessories")){
                    VStack{
                        ScrollView(.horizontal){
                            HStack(spacing: 16){
                                ForEach(model.accessories, id: \.uniqueIdentifier) { accessory in
                                    SelectButton(isSelected:
                                                    Binding(
                                                        get: { self.selectedAccessory ?? "none" },
                                                        set: { self.selectedAccessory = $0}
                                                    )
                                                 , color: .blue, text: "\(accessory.name)")
                                    .onTapGesture {
                                        selectedAccessory = "\(accessory.name)"
                                        selectedAccessoryId = accessory.uniqueIdentifier
                                    }
                                    .padding()
                                }
                                RoutePickerView(selectedAccessoryId: $selectedAccessoryId, selectedAccessory: $selectedAccessory, spotify: $spotify)
                                    .frame(width: 100, height: 50) // adjust as needed
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .padding()
                            }
                        }.onAppear(){model.findAccessories(homeId: homeId)}
                        .onChange(of: homeId, perform: { newValue in
                                model.findAccessories(homeId: newValue)
                        })
                        if selectedAccessoryId != nil {
                            ServicesView(accessoryId: $selectedAccessoryId, homeId: $homeId, model: model)
                        }
                        if selectedAccessoryId == nil && spotify {
                            SpotifyWebView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
                Spacer()
                
                if let image = blemanager.thisImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .padding()
                } else {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 100)
                        .padding()
                }
                
                Spacer()
                Button(action: {
                    print("setting up camera")
                    blemanager.scanForPeripherals()
                }){
                    Text("Scan for Banji")
                }
            }
        }
    }
}


