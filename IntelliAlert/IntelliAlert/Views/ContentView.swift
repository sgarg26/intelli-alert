//
//  ContentView.swift
//  IntelliAlert
//
//  Created by Anish Kadali on 3/29/25.
//


// File: IntelliAlert/Views/ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                HomeView(authManager: authManager)
            } else {
                LoginView(authManager: authManager)
            }
        }
        .environmentObject(authManager)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
