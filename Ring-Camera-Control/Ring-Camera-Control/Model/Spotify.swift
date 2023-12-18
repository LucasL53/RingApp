//
//  Spotify.swift
//  Ring-Camera-Control
//
//  Created by Yunseo Lee on 9/24/23.
//

import Foundation

enum APIConstants {
    static let apiHost = "api.spotify.com"
    static let authHost = "accounts.spotify.com"
    static let clientId = "b36f41e730e74e1598ba72047fe2780a"
    static let clientSecret = "2e1d4f1e73754feb997be39c6a617ba1"
    static let redirectUri = "https://www.google.com"
    static let responseType = "token"
    static let scopes = "user-read-private"
    
    static var authParams = [
        "response_type": responseType,
        "client_id": clientId,
        "redirect_uri": redirectUri,
        "scope": scopes
    ]
}

class SpotifyController: NSObject, SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
      print("connected")
    }
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
      print("disconnected")
    }
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
      print("failed")
    }
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
      print("player state changed")
    }
    
    let SpotifyClientID = APIConstants.clientId
    let SpotifyRedirectURL = URL(string: "spotify-ios-quick-start://spotify-login-callback")!
    
    var accessToken = ""

    lazy var configuration = SPTConfiguration(
      clientID: SpotifyClientID,
      redirectURL: SpotifyRedirectURL
    )
    
    lazy var appRemote: SPTAppRemote = {
      let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
      appRemote.connectionParameters.accessToken = self.accessToken
      appRemote.delegate = self
      return appRemote
    }()
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      let parameters = appRemote.authorizationParameters(from: url);

            if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
                appRemote.connectionParameters.accessToken = access_token
                self.accessToken = access_token
            } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
                // Show the error
            }
      return true
    }

}
