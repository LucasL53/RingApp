import SwiftUI
import HomeKit

struct CharacteristicsView: View {
    
    var serviceId: UUID
    var accessoryId: UUID
    var homeId: UUID
    @ObservedObject var model: HomeStore
    
    @State var hueSlider: Float = 0
    @State var brightnessSlider: Float = 0
    
    var body: some View {
        Text("Opened Characteristics...")
        List {
            Section(header: HStack {
                Text("\(model.services.first(where: {$0.uniqueIdentifier == serviceId})?.name ?? "No Service Name Found") Characteristics")
            }) {
                ForEach(model.characteristics, id: \.uniqueIdentifier) { characteristic in
                    NavigationLink(value: characteristic){
                        Text("\(characteristic.localizedDescription)")
                    }.navigationDestination(for: HMCharacteristic.self) {
                        Text($0.metadata?.description ?? "No metadata found")
                    }
                }
            }
            Section(header: HStack {
                Text("\(model.services.first(where: {$0.uniqueIdentifier == serviceId})?.name ?? "No Service Name Found") Characteristics Values")
            }) {
                if model.services.first(where: {$0.uniqueIdentifier == serviceId})?.characteristics.first(where: {$0.localizedDescription == "Power State"}) != nil {
                    Button("Read Characteristics State") {
                        model.readCharacteristicValues(serviceId: serviceId)
                    }
                    Text("Power state: \(model.powerState?.description ?? "no value found")")
                    Text("Hue value: \(model.hueValue?.description ?? "no value found")")
                    Text("Brightness value: \(model.brightnessValue?.description ?? "no value found")")
                }
            }
            Section(header: HStack {
                Text("\(model.services.first(where: {$0.uniqueIdentifier == serviceId})?.name ?? "No Service Name Found") Characteristics Control")
            }) {
                Button("Toggle Power") {
                    if model.powerState! {
                        model.setCharacteristicValue(characteristicID: model.characteristics.first(where: {$0.localizedDescription == "Power State"})?.uniqueIdentifier, value: false)
                    } else {
                        model.setCharacteristicValue(characteristicID: model.characteristics.first(where: {$0.localizedDescription == "Power State"})?.uniqueIdentifier, value: true)
                    }
                }
                Slider(value: $hueSlider, in: 0...360) { _ in
                    model.setCharacteristicValue(characteristicID: model.characteristics.first(where: {$0.localizedDescription == "Hue"})?.uniqueIdentifier, value: Int(hueSlider))
                }
                Slider(value: $brightnessSlider, in: 0...100) { _ in
                    model.setCharacteristicValue(characteristicID: model.characteristics.first(where: {$0.localizedDescription == "Brightness"})?.uniqueIdentifier, value: Int(brightnessSlider))
                }
            }
        }.onAppear(){model.findCharacteristics(serviceId: serviceId, accessoryId: accessoryId, homeId: homeId)
                     model.readCharacteristicValues(serviceId: serviceId)}
        
    }
}
