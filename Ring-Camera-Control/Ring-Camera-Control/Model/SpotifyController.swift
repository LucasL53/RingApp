////
////  SpotifyController.swift
////  Ring-Camera-Control
////
////  Created by Yunseo Lee on 8/21/23.
////
//
//import Foundation
//
//class SpotifyController {
//    let accessToken: String
//    let playerEndpoint = "https://api.spotify.com/v1/me/player/"
//
//    init(accessToken: String) {
//        self.accessToken = accessToken
//    }
//
//    private func sendRequest(endpoint: String, method: String, body: [String: Any]? = nil) {
//        guard let url = URL(string: endpoint) else { return }
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        
//        if let body = body {
//            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        }
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error occurred: \(error)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("Invalid response")
//                return
//            }
//
//            if httpResponse.statusCode == 204 {
//                print("Request successful")
//            } else if httpResponse.statusCode == 401 {
//                print("Unauthorized: Check your access token")
//            } else {
//                print("Received unexpected status code \(httpResponse.statusCode)")
//            }
//
//            // Optionally, you can parse the data into a model or take other actions
//            // if let data = data { ... }
//        }
//        task.resume()
//    }
//
//    func play() {
//        sendRequest(endpoint: playerEndpoint + "play", method: "PUT")
//    }
//
//    func pause() {
//        sendRequest(endpoint: playerEndpoint + "pause", method: "PUT")
//    }
//
//    func setVolume(volume: Int) {
//        sendRequest(endpoint: playerEndpoint + "volume?volume_percent=\(volume)", method: "PUT")
//    }
//}
//
