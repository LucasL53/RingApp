//
//  CharacteristicsButtonsView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 6/27/23.
//

import SwiftUI
//import HomeKit

struct CharacteristicsButtonsView: View {
    @Binding var serviceId: UUID
    var accessoryId: UUID
    var homeId: UUID
    @ObservedObject var model: HomeStore
    
    var body: some View {
        VStack{
            Section(header: HStack{
                Text("Ring Actions")
            }){
                HStack{
                    Spacer()
                    Button(action: {
                        findButtonAction(action: "Single")
                    }) {
                        Text("Single")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        findButtonAction(action: "Double")
                    }) {
                        Text("Double")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        findButtonAction(action: "Left")
                    }) {
                        Text("Left")
                            .frame(width: 55, height: 10)
                    }.buttonStyle(OutlinedButtonStyle())
                    Spacer()
                    Button(action: {
                        findButtonAction(action: "Right")
                    }) {
                        Text("Right")
                            .frame(width: 55, height: 10)
                    }
                    .buttonStyle(OutlinedButtonStyle())
                    
                    
                    Spacer()
                }
            }
            Spacer()
            CharacteristicsView(serviceId: serviceId, accessoryId: accessoryId, homeId: homeId, model: model)
        }
    }
}

func findButtonAction(action: String){
    
}

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.blue, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}


//struct CharacteristicsButtonsView_Previews: PreviewProvider {
//    static var previews: some View {
//        CharacteristicsButtonsView(serviceId: <#UUID#>, accessoryId: <#UUID#>, homeId: <#UUID#>, model: <#HomeStore#>)
//    }
//}
