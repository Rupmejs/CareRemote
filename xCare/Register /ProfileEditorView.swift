import SwiftUI

struct ProfileEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    // Basic fields
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var descriptionText: String = ""
    @State private var uiImages: [UIImage] = []
    
    // Nanny-specific fields
    @State private var experience: String = ""
    @State private var hourlyRate: String = ""
    @State private var location: String = ""
    @State private var selectedLanguages: Set<String> = []
    @State private var selectedDays: Set<String> = []
    @State private var isAvailableWeekends: Bool = false
    
    // Parent-specific fields
    @State private var numberOfChildren: String = ""
    @State private var childrenAges: String = ""
    @State private var parentLocation: String = ""
    @State private var preferredRate: String = ""
    @State private var needsWeekends: Bool = false
    
    @State private var showingPicker = false
    @State private var errorMessage: String?

    let userType: String
    let email: String
    let existingProfile: UserProfile?
    let onSaved: (UserProfile) -> Void
    
    // Available options
    private let commonLanguages = ["English", "Spanish", "French", "German", "Italian", "Portuguese", "Russian", "Chinese", "Other"]
    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        NavigationStack {
            ZStack {
                // Background like ContentView
                Color(red: 0.96, green: 0.95, blue: 0.90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer().frame(height: 20) // Reduced to account for navigation bar
                        
                        // Header like ContentView
                        Text("xCare")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LinearGradient(
                                colors: [Color(red: 0.4, green: 0.8, blue: 1.0), Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)

                        Text(existingProfile == nil ? "Create Your Profile" : "Edit Your Profile")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.top, 10)

                        // White container like ContentView
                        VStack(spacing: 25) {
                            // Photos Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Photos")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text("\(uiImages.count)/6")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(Array(uiImages.enumerated()), id: \.offset) { index, img in
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipped()
                                                    .cornerRadius(16)
                                                    .shadow(color: .gray.opacity(0.3), radius: 6, x: 0, y: 3)
                                                
                                                Button(action: { uiImages.remove(at: index) }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(.red)
                                                        .background(Color.white, in: Circle())
                                                        .shadow(radius: 2)
                                                }
                                                .offset(x: 8, y: -8)
                                            }
                                        }

                                        Button(action: { showingPicker = true }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 35))
                                                    .foregroundColor(.blue)
                                                Text("Add Photo")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                            .frame(width: 120, height: 120)
                                            .background(Color.white)
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            )
                                            .shadow(color: .gray.opacity(0.2), radius: 6, x: 0, y: 3)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }

                            // Basic Info Section
                            VStack(spacing: 16) {
                                TextField("", text: $name, prompt: Text("Full Name").foregroundColor(.black.opacity(0.6)))
                                    .padding(16)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .foregroundColor(.black)
                                    .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)

                                HStack(spacing: 12) {
                                    TextField("", text: $age, prompt: Text("Age").foregroundColor(.black.opacity(0.6)))
                                        .keyboardType(.numberPad)
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .foregroundColor(.black)
                                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    if userType == "nanny" {
                                        TextField("", text: $location, prompt: Text("Location").foregroundColor(.black.opacity(0.6)))
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    } else {
                                        TextField("", text: $parentLocation, prompt: Text("Location").foregroundColor(.black.opacity(0.6)))
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                }

                                ZStack(alignment: .topLeading) {
                                    TextEditor(text: $descriptionText)
                                        .frame(height: 120)
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .foregroundColor(.black)
                                        .scrollContentBackground(.hidden)
                                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)

                                    if descriptionText.isEmpty {
                                        Text(userType == "nanny" ?
                                            "Tell families about your childcare experience..." :
                                            "Tell nannies about your family...")
                                            .foregroundColor(.black.opacity(0.5))
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 20)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                            
                            // Nanny-specific fields
                            if userType == "nanny" {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Professional Details")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 12) {
                                        TextField("", text: $experience, prompt: Text("Years Experience").foregroundColor(.black.opacity(0.6)))
                                            .keyboardType(.numberPad)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        TextField("", text: $hourlyRate, prompt: Text("Rate ($/hr)").foregroundColor(.black.opacity(0.6)))
                                            .keyboardType(.decimalPad)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                }
                                
                                // Availability
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Availability")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                        ForEach(daysOfWeek, id: \.self) { day in
                                            Button(action: { toggleDay(day) }) {
                                                Text(day)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(selectedDays.contains(day) ? .white : .blue)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(selectedDays.contains(day) ? Color.blue : Color.white)
                                                    .cornerRadius(10)
                                                    .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    
                                    Toggle("Available on weekends", isOn: $isAvailableWeekends)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                                
                                // Languages
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Languages")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                                        ForEach(commonLanguages, id: \.self) { language in
                                            Button(action: { toggleLanguage(language) }) {
                                                Text(language)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(selectedLanguages.contains(language) ? .white : .blue)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity)
                                                    .background(selectedLanguages.contains(language) ? Color.blue : Color.white)
                                                    .cornerRadius(10)
                                                    .shadow(color: .gray.opacity(0.1), radius: 3, x: 0, y: 1)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Parent-specific fields
                            if userType == "parent" {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Family Details")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    HStack(spacing: 12) {
                                        TextField("", text: $numberOfChildren, prompt: Text("Number of Children").foregroundColor(.black.opacity(0.6)))
                                            .keyboardType(.numberPad)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        TextField("", text: $preferredRate, prompt: Text("Budget ($/hr)").foregroundColor(.black.opacity(0.6)))
                                            .keyboardType(.decimalPad)
                                            .padding(16)
                                            .background(Color.white)
                                            .cornerRadius(12)
                                            .foregroundColor(.black)
                                            .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                    
                                    TextField("", text: $childrenAges, prompt: Text("Children's Ages (e.g., 3, 5, 8)").foregroundColor(.black.opacity(0.6)))
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .foregroundColor(.black)
                                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    Toggle("Weekend care needed", isOn: $needsWeekends)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(16)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(10)
                            }

                            Button(action: saveProfile) {
                                Text("Save & Continue")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color(red: 0.3, green: 0.6, blue: 1.0), Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.vertical, 30)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 50)
                    }
                }
                .onTapGesture { hideKeyboard() }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 18, weight: .regular))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(userType.capitalized + " Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .toolbarBackground(Color(red: 0.96, green: 0.95, blue: 0.90), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { loadExistingProfile() }
            .sheet(isPresented: $showingPicker) {
                PhotoPicker(selectionLimit: 6) { images in
                    uiImages.append(contentsOf: images)
                }
            }
        }
    }
    
    private func toggleDay(_ day: String) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private func toggleLanguage(_ language: String) {
        if selectedLanguages.contains(language) {
            selectedLanguages.remove(language)
        } else {
            selectedLanguages.insert(language)
        }
    }

    private func loadExistingProfile() {
        print("🔍 Loading profile for \(userType) - \(email)")
        
        guard let profile = existingProfile else {
            print("❌ No existing profile found")
            loadExtras()
            return
        }
        
        name = profile.name
        age = "\(profile.age)"
        descriptionText = profile.description

        uiImages.removeAll()
        for filename in profile.imageFileNames {
            if let img = FileStorageHelpers.loadImageFromDocuments(filename: filename) {
                uiImages.append(img)
            }
        }
        
        print("✅ Basic profile loaded: \(profile.name)")
        loadExtras()
    }
    
    private func loadExtras() {
        let key = "\(userType)Extras_\(email)"
        print("🔍 Looking for extras with key: \(key)")
        
        if let data = UserDefaults.standard.data(forKey: key) {
            print("✅ Found extras data")
            
            if userType == "nanny" {
                if let extras = try? JSONDecoder().decode(NannyExtras.self, from: data) {
                    experience = "\(extras.experience)"
                    hourlyRate = "\(extras.hourlyRate)"
                    location = extras.location
                    selectedLanguages = Set(extras.languages)
                    selectedDays = Set(extras.availableDays)
                    isAvailableWeekends = extras.weekendAvailability
                    print("✅ Nanny extras loaded")
                }
            } else if userType == "parent" {
                if let extras = try? JSONDecoder().decode(ParentExtras.self, from: data) {
                    numberOfChildren = "\(extras.numberOfChildren)"
                    childrenAges = extras.childrenAges
                    parentLocation = extras.location
                    preferredRate = extras.preferredRate != nil ? "\(extras.preferredRate!)" : ""
                    needsWeekends = extras.needsWeekends
                    print("✅ Parent extras loaded")
                }
            }
        } else {
            print("❌ No extras found for key: \(key)")
        }
    }

    private func saveProfile() {
        guard !uiImages.isEmpty else {
            errorMessage = "Please add at least one photo."
            return
        }
        guard let ageInt = Int(age), ageInt > 0 else {
            errorMessage = "Please enter a valid age."
            return
        }
        guard !name.isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        guard !descriptionText.isEmpty else {
            errorMessage = "Please add a description."
            return
        }
        
        if userType == "nanny" {
            guard !experience.isEmpty else {
                errorMessage = "Please enter your years of experience."
                return
            }
            guard !hourlyRate.isEmpty else {
                errorMessage = "Please enter your hourly rate."
                return
            }
            guard !location.isEmpty else {
                errorMessage = "Please enter your location."
                return
            }
            guard !selectedLanguages.isEmpty else {
                errorMessage = "Please select at least one language."
                return
            }
            guard !selectedDays.isEmpty else {
                errorMessage = "Please select your available days."
                return
            }
        }
        
        if userType == "parent" {
            guard !numberOfChildren.isEmpty else {
                errorMessage = "Please enter number of children."
                return
            }
            guard !childrenAges.isEmpty else {
                errorMessage = "Please enter children's ages."
                return
            }
            guard !parentLocation.isEmpty else {
                errorMessage = "Please enter your location."
                return
            }
        }

        errorMessage = nil

        var filenames: [String] = []
        for img in uiImages {
            if let saved = FileStorageHelpers.saveImageToDocuments(img) {
                filenames.append(saved)
            }
        }

        let profile = UserProfile(
            userType: userType,
            email: email,
            name: name,
            age: ageInt,
            description: descriptionText,
            imageFileNames: filenames
        )

        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "\(userType)_profile_\(email)")
            print("✅ Basic profile saved")
        }
        
        saveExtras()

        onSaved(profile)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveExtras() {
        let key = "\(userType)Extras_\(email)"
        print("💾 Saving extras with key: \(key)")
        
        if userType == "nanny" {
            let extras = NannyExtras(
                experience: Int(experience) ?? 0,
                hourlyRate: Double(hourlyRate) ?? 0.0,
                location: location,
                languages: Array(selectedLanguages),
                availableDays: Array(selectedDays),
                weekendAvailability: isAvailableWeekends
            )
            
            if let encoded = try? JSONEncoder().encode(extras) {
                UserDefaults.standard.set(encoded, forKey: key)
                print("✅ Nanny extras saved")
            }
        } else if userType == "parent" {
            let extras = ParentExtras(
                numberOfChildren: Int(numberOfChildren) ?? 0,
                childrenAges: childrenAges,
                location: parentLocation,
                preferredRate: !preferredRate.isEmpty ? Double(preferredRate) : nil,
                needsWeekends: needsWeekends
            )
            
            if let encoded = try? JSONEncoder().encode(extras) {
                UserDefaults.standard.set(encoded, forKey: key)
                print("✅ Parent extras saved")
            }
        }
        
        UserDefaults.standard.synchronize()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct NannyExtras: Codable {
    let experience: Int
    let hourlyRate: Double
    let location: String
    let languages: [String]
    let availableDays: [String]
    let weekendAvailability: Bool
}

struct ParentExtras: Codable {
    let numberOfChildren: Int
    let childrenAges: String
    let location: String
    let preferredRate: Double?
    let needsWeekends: Bool
}
