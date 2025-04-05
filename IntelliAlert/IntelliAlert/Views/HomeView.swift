// File: IntelliAlert/Views/HomeView.swift

import SwiftUI

struct HomeView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // User profile and greeting at the top left
                HStack {
                    if let profile = authManager.userProfile {
                        HStack(spacing: 12) {
                            if let imageURL = profile.imageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                            }
                            
                            // Extract first name from the full name
                            Text("Hey \(profile.name.components(separatedBy: " ").first ?? "there")!")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    } else {
                        Text("Welcome!")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                
                Text("Successfully Logged In")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let profile = authManager.userProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.id)
                                    .font(.headline)
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Survey button
                NavigationLink(destination: SurveyView(authManager: authManager)) {
                    HStack {
                        Image(systemName: "list.clipboard")
                            .font(.headline)
                        Text("Take Survey")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                
                // API Request button
                Button(action: {
                    makeAPIRequest()
                }) {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.headline)
                        Text(isLoading ? "Loading..." : "Refresh Data")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading ? Color.gray : Color.purple)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                .padding(.horizontal, 40)
                
                // Sign out button
                Button(action: {
                    authManager.signOut()
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding()
            .navigationBarTitle("IntelliAlert", displayMode: .inline)
        }
    }
    
    // Function to make API request
    private func makeAPIRequest() {
        isLoading = true
        
        // Example API request
        guard let url = URL(string: "https://api.example.com/data") else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle the response on the main thread
            DispatchQueue.main.async {
                isLoading = false
                
                // Process the data here if needed
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    // Process the data
                    print("Data received: \(data)")
                    
                    // You would typically decode the data here
                    // Example:
                    // do {
                    //     let decodedData = try JSONDecoder().decode(YourModel.self, from: data)
                    //     // Update your app state with the decoded data
                    // } catch {
                    //     print("Error decoding data: \(error)")
                    // }
                }
            }
        }.resume()
    }
}

//// Placeholder for the Survey View
//struct SurveyView: View {
//    var body: some View {
//        VStack {
//            Text("Survey Questions")
//                .font(.largeTitle)
//                .padding()
//            
//            Text("Survey content will go here...")
//                .padding()
//            
//            Spacer()
//        }
//        .navigationBarTitle("Survey", displayMode: .inline)
//    }
//}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthenticationManager()
        // Mock data for preview
        authManager.isAuthenticated = true
        authManager.userProfile = AuthenticationManager.UserProfile(
            id: "preview-id",
            name: "John Smith",
            email: "john@example.com",
            imageURL: nil
        )
        return HomeView(authManager: authManager)
    }
}
