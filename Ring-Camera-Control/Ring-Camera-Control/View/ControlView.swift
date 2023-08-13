//
//  ControlView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import HomeKit

struct ControlView: View {
    var homeId: UUID
    @ObservedObject var model: HomeStore
    @StateObject var blemanager = BluetoothManager()
    @State private var selectedAccessory: String?
    @State private var selectedAccessoryId: UUID?

    var body: some View {
        VStack{
            Spacer()
            
            Button(action: {
                print("setting up camera")
                blemanager.scanForPeripherals()
            }){
                Text(blemanager.bluetoothStateString)
            }
            Spacer()
            
            Group {
                if let image = blemanager.thisImage {
                    Spacer()
                    image
                        .frame(width: 100, height: 50)
                        .padding()
                    Spacer()
                } else {
                    Image(systemName: "photo.fill")
                }
            }
            
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
                                RoutePickerView()
                                    .frame(width: 100, height: 50) // adjust as needed
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .padding()
                                
                            }
                        }.onAppear(){model.findAccessories(homeId: homeId)}
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
}


