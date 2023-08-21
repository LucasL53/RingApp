//
//  CharacteristicsView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/20/23.
//

import SwiftUI
//import HomeKit

struct CharacteristicsView: View {
    @Binding var serviceId: UUID
    var accessoryId: UUID
    @Binding var homeId: UUID
    @ObservedObject var model: HomeStore
    
    var body: some View {
        VStack{
            Section(header: HStack{
                Text("Ring Actions")
            }){
                HStack{
                    Spacer()
                    Button(action: {
                        model.controlAccessory(accessoryIdentifier: accessoryId, control: -1)
                        model.readCharacteristicValues(serviceId: serviceId)
                    }) {
                        Text("Single")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        model.controlAccessory(accessoryIdentifier: accessoryId, control: 100)
                        model.readCharacteristicValues(serviceId: serviceId)
                    }) {
                        Text("Double")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        model.controlAccessory(accessoryIdentifier: accessoryId, control: 50)
                        model.readCharacteristicValues(serviceId: serviceId)
                    }) {
                        Text("Left")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        model.controlAccessory(accessoryIdentifier: accessoryId, control: 0)
                        model.readCharacteristicValues(serviceId: serviceId)
                    }) {
                        Text("Right")
                            .frame(width: 55, height: 10)
                    }
                    .buttonStyle(OutlinedButtonStyle())
                    
                    
                    Spacer()
                }
            }
            Spacer()
            Section(header: HStack {
                Text("\(model.services.first(where: {$0.uniqueIdentifier == serviceId})?.name ?? "No Service Name Found") Characteristics Values")
            }) {
                if let service = model.services.first(where: {$0.uniqueIdentifier == serviceId}) {
                    Button("Read Characteristics State") {
                        model.readCharacteristicValues(serviceId: serviceId)
                    }
                    ForEach(service.characteristics, id: \.uniqueIdentifier) { characteristic in
                        Text("\(characteristic.localizedDescription): \((model.characteristicValue(for: characteristic) as AnyObject).description ?? "no value found")")
                    }
                }
            }
        }
    }
}

func findButtonAction(action: String){
    
}
