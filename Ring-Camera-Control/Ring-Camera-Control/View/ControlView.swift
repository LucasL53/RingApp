//
//  ControlView.swift
//  Ring-Camera-Control
//  ControlView has the main accessories of the selected Home
//  And a routerpicker to connect to Airplay2 fo TV/HomePod
//  Created by Yunseo Lee on 8/12/23.
//

import SwiftUI
import HomeKit

enum exampleClass: String, CaseIterable, Identifiable {
    case lights = "Lights"
    case speaker = "Speaker"
    case lock = "Lock"
    case tv = "TV"
    case blinds = "Blinds"

    var id: exampleClass { self }
}

struct ControlView: View {
    @Binding var homeId: UUID?
    @ObservedObject var model: HomeStore
    @StateObject var blemanager = BluetoothManager()
    @ObservedObject var musicModel = MusicModel.shared
//    @State private var selectedAccessory: String?
    @State private var selectedAccessoryId: UUID? = UUID(uuidString: "1A7337DD-577D-510E-8E50-5E91C5B8BE34")
    @State private var spotify: Bool = false

    var body: some View {
        VStack{
            ScrollView {
                Section(header: Text("IRIS:")
                    .bold()
                    .font(.title) // Increase the font size
                    .frame(maxWidth: .infinity, alignment: .leading)) {
                    Spacer()
                        
                        if blemanager.banjiStatus {
                            Image("RingLighter")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .accessibilityLabel("Ring connected")
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
//                                    .onTapGesture {
//                                        blemanager.banjiStatus = false
//                                    }
                            Text("IRIS Connected")
                                .font(.caption)
                        } else {
                            Image("RingDarker")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .accessibilityLabel("Ring disconnected")
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
//                                    .onTapGesture {
//                                        blemanager.banjiStatus = true
//                                    }
                            Text("Searching for IRIS")
                                .font(.caption)
                        }
                    
                }
                Spacer()
//                HStack{
//                    RouterPicker()
//                        .frame(width: 100, height: 50) // adjust as needed
//                        .background(Color.blue)
//                        .clipShape(RoundedRectangle(cornerRadius: 25.0))
//                        .padding()
//                }
                
                Spacer()
//                Section(header: Text("My Smart Home Device")
//                    .frame(maxWidth: .infinity, alignment: .leading)) {
//                    Picker("My Smart Home Device", selection: $selectedAccessoryId){
//                        ForEach(exampleClass.allCases) { category in
//                             Text(category.rawValue).tag(category)
//                       }
//                    }
//                    .pickerStyle(.segmented)
//                    .onReceive(blemanager.$prediction) { newPrediction in
//                        if let newPrediction = newPrediction {
//                            selectedAccessoryId = newPrediction
//                        }
//                    }
//                }
//                Spacer()

                Section(header: Text("Live View")
                    .frame(maxWidth: .infinity, alignment: .leading)) {
                    ZStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 500)
                            .accessibilityLabel("Live Video Feed")
                        
                        // Foreground image if available
                        if let image = blemanager.thisImage {
//                            GeometryReader { proxy in
//                                image
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: proxy.size.width * 0.95)
//                                    .frame(width: proxy.size.width, height: proxy.size.height)
//                            }
                            image
                            .resizable()
                        }
                    }
                }
                Spacer(minLength: 30)
                
//                Button(action: {
//                    blemanager.savePicture()
//                }) {
//                    Text("Save Picture")
//                        .frame(width: 110, height: 10)
//                }
//                .buttonStyle(OutlinedButtonStyle())
//                Spacer(minLength: 30)
//                
//                Button(action: {
//                    model.toggleAccessory(accessoryIdentifier: UUID(uuidString: model.homeDictionary["lights"]!)!)
//                }) {
//                    Text("Toggle Bulb")
//                        .frame(width: 110, height: 10)
//                }
//                .buttonStyle(OutlinedButtonStyle())
//                Spacer(minLength: 30)
//                
//                
//                if spotify {
//                    Image(systemName: "pause.fill")
//                        .font(.title)
//                        .onTapGesture {
//                            musicModel.pause()
//                            spotify = false
//                        }
//                } else {
//                    Image(systemName: "play.fill")
//                        .font(.title)
//                        .onTapGesture {
//                            musicModel.resumePlayback()
//                            spotify = true
//                        }
//                }
            }
        }.onChange(of: blemanager.banjiStatus) {
            blemanager.scanForPeripherals()
            blemanager.setHomeStore(homeStore: model)
        }
    }
}
