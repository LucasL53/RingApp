import SwiftUI
import HomeKit

struct AccessoriesView: View {
    
    var homeId: UUID
    @ObservedObject var model: HomeStore
    @State private var selectedAccessory: String?
    @State private var selectedAccessoryId: UUID?

    var body: some View {
        ScrollView{
            VStack{
                Section(header: HStack {
                    Text("My Accessories")
                }) {
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
                        }
                    }
                    .onAppear(){
                        model.findAccessories(homeId: homeId)
                    }
                    if let selectedAccessoryId = selectedAccessoryId {
                        ServicesView(accessoryId: selectedAccessoryId, homeId: homeId, model: model)
                    }
                }
            }
        }
    }
}
