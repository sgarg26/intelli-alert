// File: IntelliAlert/App/IntelliAlertApp.swift

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct IntelliAlertApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
