//
//  CharacteristicsButtonsView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 6/27/23.
//

import SwiftUI
//import HomeKit

struct CharacteristicsButtonsView: View {
    var body: some View {
        Section(header: HStack{
            Text("Ring Actions")
        }){
            HStack{
                Spacer()
                Button(action: {
                    findButtonAction()
                }) {
                    Text("Single")
                        .frame(width: 55, height: 10)
                }.buttonStyle(OutlinedButtonStyle())
                Spacer()
                Button(action: {
                    findButtonAction()
                }) {
                    Text("Double")
                        .frame(width: 55, height: 10)
                }.buttonStyle(OutlinedButtonStyle())
                Spacer()
                Button(action: {
                    findButtonAction()
                }) {
                    Text("Left")
                        .frame(width: 55, height: 10)
                }.buttonStyle(OutlinedButtonStyle())
                Spacer()
                Button(action: {
                    findButtonAction()
                }) {
                    Text("Right")
                        .frame(width: 55, height: 10)
                }
                .buttonStyle(OutlinedButtonStyle())
                
                
                Spacer()
            }
        }
    }
}

func findButtonAction(){
    print("hello world")
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


struct CharacteristicsButtonsView_Previews: PreviewProvider {
    static var previews: some View {
            CharacteristicsButtonsView()
    }
}
