//
//  AuthenticationManager.swift
//  IntelliAlert
//
//  Created by Anish Kadali on 3/29/25.
//


// File: IntelliAlert/Authentication/AuthenticationManager.swift

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import FirebaseCore

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    struct UserProfile {
        let id: String
        let name: String
        let email: String
        let imageURL: URL?
    }
    
    init() {
        // Check if user is already signed in
        if let user = Auth.auth().currentUser, let googleUser = GIDSignIn.sharedInstance.currentUser {
            self.isAuthenticated = true
            self.userProfile = createUserProfile(from: googleUser)
        }
    }
    
    func signIn() {
        self.isLoading = true
        self.errorMessage = nil
        
        // Get client ID from GoogleService-Info.plist through FirebaseApp
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            self.errorMessage = "Firebase configuration error"
            self.isLoading = false
            return
        }
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            self.errorMessage = "Cannot find the presenting view controller"
            self.isLoading = false
            return
        }
        
        // Configure GIDSignIn with the client ID
        let config = GIDConfiguration(clientID: clientID)
        
        // Start the sign-in flow using the correct method signature
        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        ) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Google Sign-In error: \(error.localizedDescription)"
                    return
                }
                
                guard let result = result else {
                    self.errorMessage = "Sign-in failed with no result"
                    return
                }
                
                let user = result.user
                
                // Get the Google ID token
                guard let idToken = user.idToken?.tokenString else {
                    self.errorMessage = "Failed to get ID token"
                    return
                }
                
                // Create Firebase credential with the Google ID token
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                
                // Sign in to Firebase with the Google Auth credential
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = "Firebase sign-in error: \(error.localizedDescription)"
                            return
                        }
                        
                        // Successfully signed in to both Google and Firebase
                        self.isAuthenticated = true
                        self.userProfile = self.createUserProfile(from: user)
                    }
                }
            }
        }
    }
    
    private func createUserProfile(from user: GIDGoogleUser) -> UserProfile {
        let profile = user.profile
        let firebaseUserID = Auth.auth().currentUser?.uid ?? "" // Use Firebase user ID
        return UserProfile(
            id: firebaseUserID, // Store Firebase user ID
            name: profile?.name ?? "Unknown",
            email: profile?.email ?? "",
            imageURL: profile?.imageURL(withDimension: 100)
        )
    }
    
    func signOut() {
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
        } catch {
            print("Firebase sign out error: \(error.localizedDescription)")
        }
        
        // Sign out from Google
        GIDSignIn.sharedInstance.signOut()
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userProfile = nil
        }
    }
}
