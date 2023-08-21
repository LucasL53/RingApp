//
//  RoutePickerView.swift
//  Ring Project
//
//  Created by Yunseo Lee on 7/6/23.
//

import SwiftUI
import AVKit

struct RoutePickerView: UIViewRepresentable {
    @Binding var selectedAccessoryId: UUID?
    @Binding var selectedAccessory: String?
    @Binding var spotify: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.delegate = context.coordinator
        picker.activeTintColor = .blue
        picker.tintColor = .blue
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No update needed
    }

    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        var parent: RoutePickerView

        init(_ parent: RoutePickerView) {
            self.parent = parent
        }

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            parent.selectedAccessoryId = nil
            parent.selectedAccessory = "none"
            parent.spotify = true
        }
    }
}

