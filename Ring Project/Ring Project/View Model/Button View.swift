//
//  Sticky Button View.swift
//  Ring Project
//
//  Created by Yunseo Lee on 5/4/23.
//

import SwiftUI


struct ButtonView: View {
    @State private var isLightOn = false
    // Define an array of tuples to hold the appliances and their on/off state
    @State private var appliances: [(name: String, isOn: Bool)] = [
        ("Appliance 1", false),
        ("Appliance 2", true),
        ("Appliance 3", true),
        ("Appliance 4", false),
        ("Appliance 5", true),
        ("Appliance 6", false),
    ]
    
    // Define the number of columns in the grid
    let columns = 2
    
    var body: some View {
        
        VStack {
//            LightSwitchSlider(isOn: $isLightOn)
//                            .padding()
//
//                        Text("Light is " + (isLightOn ? "On" : "Off"))
//                            .padding()
            Text("Frequently Used: ")
                .font(.title2)
                .padding()
            // Create a grid of buttons using a ForEach loop and the gridItem modifier
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: columns), spacing: 20) {
                ForEach(appliances.indices, id: \.self) { index in
                    // Get the appliance name and state from the array
                    let appliance = appliances[index]
                    
                    // Create a button to toggle the appliance state
                    Button(action: {
                        appliances[index].isOn.toggle()
                    }) {
                        // Customize the button appearance based on the appliance state
                        Text(appliance.name)
                            .foregroundColor(appliance.isOn ? .green : .red)
                            .padding(.vertical, 30)
                            .padding(.horizontal, 40)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 2)
                    }
                    
                    // Toggle Version (TESTING)
                    
                }
            }
            
            // Add a button to add more appliances in the future
            Button(action: {
                appliances.append(("New Appliance", false))
            }){
                Text("Add Appliance")
                    .foregroundColor(.white)
                    .padding(.vertical, 30)
                    .padding(.horizontal, 40)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding(.top, 20)
//            .buttonStyle(RadioToggleStyle())
        }
        .padding()
        .navigationTitle("Home")
    }
}

struct RadioToggleStyle: ToggleStyle{
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Button{
                configuration.isOn.toggle()
            }label: {
                Image(systemName: configuration.isOn ? "smallcircle.circle.fill" : "smallcircle.circle")
            }
            .padding(30)
            .font(.title3)
            .accentColor(configuration.isOn ? Color.green: Color.gray)
        }
    }
}
