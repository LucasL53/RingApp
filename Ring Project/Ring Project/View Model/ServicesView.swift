import SwiftUI
import HomeKit

struct ServicesView: View {
    var accessoryId: UUID
    var homeId: UUID
    
    @ObservedObject var model: HomeStore
    @State private var selectedService: String?
    @State private var selectedServiceId: UUID?
    
    var body: some View {
        Section(header: HStack {
            Text("\(model.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.name ?? "No Accessory Found") Services")
        }){
            ScrollView(.horizontal){
                    HStack(spacing: 16){
                        ForEach(model.accessories.first(where: {$0.uniqueIdentifier == accessoryId})?.services ?? [], id: \.uniqueIdentifier) { service in
                            SelectButton(isSelected:
                                            Binding(
                                                get: { selectedService ?? "none" },
                                                set: { selectedService = $0}
                                            )
                                            , color: .blue, text: "\(service.name)")
                            .onTapGesture {
                                // Fix bug where if Services selected but accessory changed, serviceSelected in not reset
                                selectedService = "\(service.name)"
                                selectedServiceId = service.uniqueIdentifier
                            }
                            .padding()
                        }
                    }
            }.onAppear(){
                model.findServices(accessoryId: accessoryId, homeId: homeId)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
        CharacteristicsButtonsView()
//        if let selectedServiceId = selectedServiceId {
//            CharacteristicsView(serviceId: selectedServiceId, accessoryId: accessoryId, homeId: homeId, model: model)
//        }
    }
}
