//
//  ServicesView.swift
//  Ring-Camera-Control
//  When given an accessory to control, list the
//  Available services
//  Created by Yunseo Lee on 8/15/23.
//

import SwiftUI
import HomeKit

struct ServicesView: View {
    @Binding var accessoryId: UUID?
    @Binding var homeId: UUID
    
    @ObservedObject var model: HomeStore
    @State private var selectedService: String = "none"
    @State private var selectedServiceId: UUID = UUID()
    
    var body: some View {
        VStack{
            Section(header: HStack {
                Text("\(model.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.name ?? "No Accessory Found") Services")
            }){
                HStack(spacing: 16){
                    ForEach(model.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services ?? [], id: \.uniqueIdentifier) { service in
                        SelectButton(isSelected: $selectedService, color: .blue, text: "\(service.humanReadableType)")
                        .onTapGesture {
                            selectedService = "\(service.humanReadableType)"
                            selectedServiceId = service.uniqueIdentifier
                        }
                        .padding()
                    }
                }.onAppear(){
                    model.findServices(accessoryId: accessoryId!, homeId: homeId)
                }
                .onChange(of: accessoryId) { newValue in
                    if let newAccessoryId = newValue {
                        model.findServices(accessoryId: newAccessoryId, homeId: homeId)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            }
            if accessoryId != nil {
                CharacteristicsView(serviceId: $selectedServiceId, accessoryId: accessoryId!, homeId: homeId, model: model)
            }
        }
    }
}

// HomeKit does not have String Names for Services, instead they have unique IDs
extension HMService {
    var humanReadableType: String {
        switch serviceType {
        case HMServiceTypeLightbulb:
            return "Lightbulb"
        case HMServiceTypeAccessoryInformation:
            return "Accessory Information"
        case HMServiceTypeWindowCovering:
            return "Window Covering"
        case HMServiceTypeLockMechanism:
            return "Lock Mechanism"
        case HMServiceTypeSpeaker:
            return "Speaker"
        default:
            return "Unknown"
        }
    }
}
