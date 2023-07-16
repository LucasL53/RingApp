//
//  SelectButton.swift
//  Ring Project
//
//  Created by Yunseo Lee on 6/18/23.
//

import SwiftUI

struct SelectButton: View {
    @Binding var isSelected: String
    @State var color: Color
    @State var text: String
    
    var body: some View{
        VStack{
            Capsule()
                .frame(width: 100, height: 50)
                .foregroundColor(isSelected == text ? color : .gray)
            Text(text)
                .foregroundColor(.white)
            
        }
    }
}

//struct SelectButton_Previews: PreviewProvider {
//    @Binding var str: String
//    static var previews: some View {
//        SelectButton(isSelected: str = "Test1", color: .blue, text: "Test")
//    }
//}
