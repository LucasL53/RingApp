import SwiftUI
import HomeKit

struct ServicesView: View {
    var accessoryId: UUID
    var homeId: UUID
    
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
                        SelectButton(isSelected:
                                        $selectedService
                                        , color: .blue, text: "\(service.name)")
                        .onTapGesture {
                            selectedService = "\(service.name)"
                            selectedServiceId = service.uniqueIdentifier
                        }
                        .padding()
                    }
                }.onAppear(){
                    model.findServices(accessoryId: accessoryId, homeId: homeId)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            }
            CharacteristicsButtonsView(serviceId: $selectedServiceId, accessoryId: accessoryId, homeId: homeId, model: model)
            
        }
    }
}
