//
//  OutlinedButtonStyle.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/20/23.
//

import SwiftUI

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


