//
//  RoutePickerView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/6/23.
//

import SwiftUI
import AVKit

struct RouterPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = .blue
        picker.tintColor = .blue
        return picker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No update needed
    }
}
