//
//  SelectButton.swift
//  Ring Project
//
//  Created by Yunseo Lee on 6/18/23.
//

import SwiftUI

struct SelectButton: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isSelected: String
    @State var color: Color
    @State var text: String
    
    var body: some View{
        VStack{
            Capsule()
                .frame(width: 100, height: 50)
                .foregroundColor(isSelected == text ? color : .gray)
                .accessibilityAddTraits(.isToggle)
            Text(text)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
        }
    }
}
