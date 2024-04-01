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
    @Binding var homeEmbedding: HomeEmbeddings?
    @ObservedObject var model: HomeStore
    @ObservedObject var blemanager = BluetoothManager()
    @ObservedObject var musicModel = MusicModel.shared
//    @State private var selectedAccessory: String?
    @State private var selectedAccessoryId: UUID? = UUID(uuidString: "1A7337DD-577D-510E-8E50-5E91C5B8BE34")
    @State private var spotify: Bool = false
    @State private var tempBool: Bool = false

    var body: some View {
            VStack{
                ScrollView {
                    HStack {
                        Spacer(minLength: 20)
                        VStack {
                            Section (header: Text("IRIS")
                                .bold()
                                .font(.title) // Increase the font size
                                .frame(maxWidth: .infinity, alignment: .leading))
                            {
                                Spacer()
                                
                                if blemanager.banjiStatus {
                                    VStack {
                                        Image("RingLighter")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100, alignment: .leading)
                                            .accessibilityLabel("Ring connected symbol")
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .onTapGesture {
                                                tempBool.toggle()
                                            }
                                        Text("IRIS Connected")
                                            .font(.caption)
                                            .frame(alignment: .leading)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                    
                                } else {
                                    VStack {
                                        Image("RingDarker")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100, alignment: .leading)
                                            .accessibilityLabel("Ring disconnected symbol")
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .onTapGesture {
                                                tempBool.toggle()
                                            }
                                        Text("Searching for IRIS")
                                            .font(.caption)
                                            .frame(alignment: .leading)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                    
                                }
                                
                            }
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
                    
                    //                Spacer()
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
                    HStack {
                        Spacer(minLength: 20)
                        
                        VStack {
                            Section(header: Text("Live View")
                                .bold()
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity, alignment: .leading)) {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(height: 480)
                                            .cornerRadius(/*@START_MENU_TOKEN@*/3.0/*@END_MENU_TOKEN@*/)
                                            .accessibilityLabel("Live Video Feed")
                                        
                                        // Foreground image if available
                                        if let image = blemanager.thisImage {
                                            image
                                                .resizable()
                                        }
                                    }
                                }
                            Spacer(minLength: 10)
                            NavigationView {
                                if let embedding = homeEmbedding {
                                    NavigationLink(destination: SetUpView(home: embedding)) {
                                        Text("Add New IRIS Device Reference")
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }.buttonStyle(OutlinedButtonStyle())
                                }
                            }
                            
                        }
                        
                        
                        Spacer(minLength: 20)
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
            }
        .onChange(of: blemanager.banjiStatus) {
            blemanager.scanForPeripherals()
            blemanager.setHomeStore(homeStore: model)
        }
    }
}
