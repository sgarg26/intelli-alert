//
//  SurveyView.swift
//  IntelliAlert
//
//  Created by Anish Kadali on 3/29/25.
//


// File: IntelliAlert/Views/SurveyView.swift

import SwiftUI

struct EmergencyContact: Identifiable, Codable {
    var id = UUID()
    var name: String
    var relationship: String
    var phoneNumber: String
}

struct MedicalInfo: Codable {
    var conditions: [String]
    var allergies: [String]
    var medications: [String]
    var bloodType: String
    var organDonor: Bool
}

struct EmergencyPreferences: Codable {
    var preferredHospital: String
    var doctorName: String
    var doctorPhone: String
    var specialInstructions: String
}

struct LocationInfo: Codable {
    var homeAddress: String
    var workAddress: String
    var otherFrequentLocations: [String]
}

struct UserEmergencyProfile: Codable {
    var fullName: String
    var dateOfBirth: Date
    var phoneNumber: String
    var emergencyContacts: [EmergencyContact]
    var medicalInfo: MedicalInfo
    var emergencyPreferences: EmergencyPreferences
    var locationInfo: LocationInfo
}

// Change the SurveyViewModel initializer to accept an AuthenticationManager
class SurveyViewModel: ObservableObject {
    @Published var userProfile = UserEmergencyProfile(
        fullName: "",
        dateOfBirth: Date(),
        phoneNumber: "",
        emergencyContacts: [],
        medicalInfo: MedicalInfo(
            conditions: [],
            allergies: [],
            medications: [],
            bloodType: "Unknown",
            organDonor: false
        ),
        emergencyPreferences: EmergencyPreferences(
            preferredHospital: "",
            doctorName: "",
            doctorPhone: "",
            specialInstructions: ""
        ),
        locationInfo: LocationInfo(
            homeAddress: "",
            workAddress: "",
            otherFrequentLocations: []
        )
    )
    
    @Published var tempMedicalCondition = ""
    @Published var tempAllergy = ""
    @Published var tempMedication = ""
    @Published var tempLocation = ""
    @Published var tempContact = EmergencyContact(name: "", relationship: "", phoneNumber: "")
    
    // Store authManager as a property
    private var authManager: AuthenticationManager
    
    // Initialize with authManager
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
    }
    
    func saveProfile() {
        // Save to UserDefaults temporarily
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: "EmergencyProfile")
            
            // Prepare to send to server
            sendProfileToServer(profile: userProfile)
        }
    }

    func sendProfileToServer(profile: UserEmergencyProfile) {
        // Create URL with the profile ID as a parameter
        guard let userProfile = authManager.userProfile,
        let url = URL(string: "https://api.intellialert.xyz/users/update_profile/\(userProfile.id)") else {
            print("Invalid URL")
            return
        }
        
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the profile as JSON and attach to the request
        do {
            let jsonData = try JSONEncoder().encode(profile)
            request.httpBody = jsonData
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            } else {
                print("Failed to convert JSON data to string")
            }
            // Create and start the data task
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending profile: \(error)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("No HTTP response")
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("Profile successfully updated on server")
                    
                    // Handle the response data if needed
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("Server response: \(responseString)")
                    }
                } else {
                    print("Server returned status code: \(httpResponse.statusCode)")
                }
            }
            
            task.resume()
        } catch {
            print("Failed to encode profile: \(error)")
        }
    }
    
    func loadProfile() {
        if let savedProfile = UserDefaults.standard.data(forKey: "EmergencyProfile"),
           let loadedProfile = try? JSONDecoder().decode(UserEmergencyProfile.self, from: savedProfile) {
            self.userProfile = loadedProfile
        }
    }
}

struct SurveyView: View {
    @ObservedObject var authManager: AuthenticationManager
    // Initialize viewModel with authManager instead of creating a new one
    @StateObject private var viewModel: SurveyViewModel
    @State private var currentPage = 0
    @State private var showingSaveAlert = false
    
    // Initialize SurveyView with authManager and pass it to viewModel
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        // Use StateObject with wrappedValue to create the viewModel with the authManager
        _viewModel = StateObject(wrappedValue: SurveyViewModel(authManager: authManager))
    }
    
    // Blood type options
    let bloodTypes = ["Unknown", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
    
    var body: some View {
        VStack {
            // Progress indicator
            HStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(currentPage >= index ? Color.blue : Color.gray)
                        .frame(width: 12, height: 12)
                }
                Spacer()
                
                Text("\(currentPage + 1)/5")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            TabView(selection: $currentPage) {
                // Page 1: Basic Information
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("This information helps emergency services identify you quickly.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        Group {
                            Text("Full Name").font(.headline)
                            TextField("Full Name", text: $viewModel.userProfile.fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Date of Birth").font(.headline)
                            DatePicker("", selection: $viewModel.userProfile.dateOfBirth, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                            
                            Text("Phone Number").font(.headline)
                            TextField("Phone Number", text: $viewModel.userProfile.phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                    .padding()
                }
                .tag(0)
                
                // Page 2: Emergency Contacts
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Emergency Contacts")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("Who should be notified in case of an emergency?")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        ForEach(viewModel.userProfile.emergencyContacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(contact.name).font(.headline)
                                    Text(contact.relationship).font(.subheadline)
                                    Text(contact.phoneNumber).font(.caption)
                                }
                                Spacer()
                                Button(action: {
                                    viewModel.userProfile.emergencyContacts.removeAll { $0.id == contact.id }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Add Contact").font(.headline)
                            
                            TextField("Contact Name", text: $viewModel.tempContact.name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Relationship", text: $viewModel.tempContact.relationship)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Phone Number", text: $viewModel.tempContact.phoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            Button(action: {
                                let newContact = EmergencyContact(
                                    name: viewModel.tempContact.name,
                                    relationship: viewModel.tempContact.relationship,
                                    phoneNumber: viewModel.tempContact.phoneNumber
                                )
                                viewModel.userProfile.emergencyContacts.append(newContact)
                                viewModel.tempContact = EmergencyContact(name: "", relationship: "", phoneNumber: "")
                            }) {
                                Text("Add Contact")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .disabled(viewModel.tempContact.name.isEmpty || viewModel.tempContact.phoneNumber.isEmpty)
                        }
                    }
                    .padding()
                }
                .tag(1)
                
                // Page 3: Medical Information
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Medical Information")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("Critical medical details for emergency responders.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        Group {
                            Text("Medical Conditions").font(.headline)
                            ForEach(viewModel.userProfile.medicalInfo.conditions, id: \.self) { condition in
                                HStack {
                                    Text(condition)
                                    Spacer()
                                    Button(action: {
                                        viewModel.userProfile.medicalInfo.conditions.removeAll { $0 == condition }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            HStack {
                                TextField("Add Medical Condition", text: $viewModel.tempMedicalCondition)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !viewModel.tempMedicalCondition.isEmpty {
                                        viewModel.userProfile.medicalInfo.conditions.append(viewModel.tempMedicalCondition)
                                        viewModel.tempMedicalCondition = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Allergies").font(.headline).padding(.top)
                            ForEach(viewModel.userProfile.medicalInfo.allergies, id: \.self) { allergy in
                                HStack {
                                    Text(allergy)
                                    Spacer()
                                    Button(action: {
                                        viewModel.userProfile.medicalInfo.allergies.removeAll { $0 == allergy }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            HStack {
                                TextField("Add Allergy", text: $viewModel.tempAllergy)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !viewModel.tempAllergy.isEmpty {
                                        viewModel.userProfile.medicalInfo.allergies.append(viewModel.tempAllergy)
                                        viewModel.tempAllergy = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Medications").font(.headline).padding(.top)
                            ForEach(viewModel.userProfile.medicalInfo.medications, id: \.self) { medication in
                                HStack {
                                    Text(medication)
                                    Spacer()
                                    Button(action: {
                                        viewModel.userProfile.medicalInfo.medications.removeAll { $0 == medication }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            HStack {
                                TextField("Add Medication", text: $viewModel.tempMedication)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !viewModel.tempMedication.isEmpty {
                                        viewModel.userProfile.medicalInfo.medications.append(viewModel.tempMedication)
                                        viewModel.tempMedication = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Text("Blood Type").font(.headline).padding(.top)
                            Picker("Blood Type", selection: $viewModel.userProfile.medicalInfo.bloodType) {
                                ForEach(bloodTypes, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                            Toggle("Organ Donor", isOn: $viewModel.userProfile.medicalInfo.organDonor)
                                .padding(.top)
                        }
                    }
                    .padding()
                }
                .tag(2)
                
                // Page 4: Emergency Preferences
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Emergency Preferences")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("Your preferences for emergency care.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        Group {
                            Text("Preferred Hospital").font(.headline)
                            TextField("Hospital Name", text: $viewModel.userProfile.emergencyPreferences.preferredHospital)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Doctor's Name").font(.headline)
                            TextField("Doctor's Name", text: $viewModel.userProfile.emergencyPreferences.doctorName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Doctor's Phone Number").font(.headline)
                            TextField("Doctor's Phone", text: $viewModel.userProfile.emergencyPreferences.doctorPhone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            Text("Special Instructions").font(.headline)
                            TextEditor(text: $viewModel.userProfile.emergencyPreferences.specialInstructions)
                                .frame(minHeight: 100)
                                .border(Color.gray.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                }
                .tag(3)
                
                // Page 5: Location Information
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Location Information")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)
                        
                        Text("Your frequent locations help responders find you quickly.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom)
                        
                        Group {
                            Text("Home Address").font(.headline)
                            TextField("Home Address", text: $viewModel.userProfile.locationInfo.homeAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Work Address").font(.headline)
                            TextField("Work Address", text: $viewModel.userProfile.locationInfo.workAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Other Frequent Locations").font(.headline)
                            ForEach(viewModel.userProfile.locationInfo.otherFrequentLocations, id: \.self) { location in
                                HStack {
                                    Text(location)
                                    Spacer()
                                    Button(action: {
                                        viewModel.userProfile.locationInfo.otherFrequentLocations.removeAll { $0 == location }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            HStack {
                                TextField("Add Location", text: $viewModel.tempLocation)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if !viewModel.tempLocation.isEmpty {
                                        viewModel.userProfile.locationInfo.otherFrequentLocations.append(viewModel.tempLocation)
                                        viewModel.tempLocation = ""
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.saveProfile()
                            showingSaveAlert = true
                        }) {
                            Text("Save Emergency Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(8)
                        }
                        .padding(.vertical)
                    }
                    .padding()
                }
                .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                Button(action: {
                    withAnimation {
                        currentPage = max(0, currentPage - 1)
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .padding()
                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                }
                .disabled(currentPage == 0)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if currentPage < 4 {
                            currentPage += 1
                        } else {
                            viewModel.saveProfile()
                            showingSaveAlert = true
                        }
                    }
                }) {
                    HStack {
                        Text(currentPage < 4 ? "Next" : "Save")
                        Image(systemName: currentPage < 4 ? "chevron.right" : "checkmark")
                    }
                    .padding()
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarTitle("Emergency Profile", displayMode: .inline)
        .onAppear {
            viewModel.loadProfile()
        }
        .alert(isPresented: $showingSaveAlert) {
            Alert(
                title: Text("Profile Saved"),
                message: Text("Your emergency profile has been saved successfully."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SurveyView(authManager: createMockAuthManager())
        }
    }
    
    static func createMockAuthManager() -> AuthenticationManager {
        let authManager = AuthenticationManager()
        authManager.isAuthenticated = true
        authManager.userProfile = AuthenticationManager.UserProfile(
            id: "preview-id",
            name: "John Smith",
            email: "john@example.com",
            imageURL: nil
        )
        return authManager
    }
}
