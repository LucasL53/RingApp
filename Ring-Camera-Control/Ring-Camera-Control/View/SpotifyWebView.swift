//
//  SpotifyWebView.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 8/21/23.
//

import SwiftUI
import WebKit

struct SpotifyWebView: View {
    let urlString: String = "https://open.spotify.com/embed/track/YOUR_SPOTIFY_TRACK_ID_HERE"

    var body: some View {
        VStack {
            WebView(urlString: urlString)
                .frame(height: 300)
            Button("Play") {
                play()
            }
            
            Button("Pause") {
                pause()
            }
                        
        }
    }
    
    func play() {
        // evaluateJavaScript(_:completionHandler:)
    }
    
    func pause() {
        // evaluateJavaScript(_:completionHandler:)
    }
}

struct WebView: UIViewRepresentable {
    var urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

