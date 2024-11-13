//
//  WaitlistView.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/4/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import FirebaseAuth
import Combine

struct WaitlistView: View {
    @StateObject private var viewModel = WaitlistViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0){
            VStack( spacing: 20) {
                Image("KetchupTextRed")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                Image("Skip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                InfiniteCheckersView()
                    .frame(maxWidth: .infinity, maxHeight: 50)
            }
            VStack(alignment: .leading, spacing: 20) {
                Text("You're on the waitlist!")
                    .font(.custom("MuseoSansRounded-700", size: 26))
                    .foregroundColor(.black)
                
                Text("Your current position is:")
                    .font(.custom("MuseoSansRounded-500", size: 20))
                    .foregroundColor(.gray)
                
                Text("#\(viewModel.waitlistNumber)")
                    .font(.custom("MuseoSansRounded-700", size: 40))
                    .foregroundColor(Color("Colors/AccentColor"))
                
                Text("Have a referral code? Enter it below to join Ketchup!")
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundColor(.black)
                
                TextField("Referral Code", text: $viewModel.referralCode)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                if let isValid = viewModel.isReferralValid {
                    Text(isValid ? "Referral code accepted!" : "Invalid referral code")
                        .foregroundColor(isValid ? .green : .red)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.submitReferralCode()
                    }
                }) {
                    Text(viewModel.isSubmitting ? "Submitting..." : "Submit")
                        .font(.custom("MuseoSansRounded-500", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.referralCode.isEmpty ? Color.gray : Color("Colors/AccentColor"))
                        .cornerRadius(25)
                }
                .disabled(viewModel.referralCode.isEmpty || viewModel.isSubmitting)
            }
            
            .padding(.horizontal)
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if viewModel.navigateToNextView {
                            // Handle navigation to the next view
                        }
                    }
                )
            }
            .navigationDestination(isPresented: $viewModel.navigateToNextView) {
                UsernameSelectionView()
            }
        }
        }
    }
}




@MainActor
class WaitlistViewModel: ObservableObject {
    @Published var waitlistNumber: Int = 0
    @Published var referralCode: String = "" {
        didSet {
            // Convert to lowercase whenever the value changes
            if referralCode != referralCode.lowercased() {
                referralCode = referralCode.lowercased()
            }
        }
    }
    @Published var isReferralValid: Bool?
    @Published var isSubmitting: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var navigateToNextView: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchWaitlistNumber()
    }

    func fetchWaitlistNumber() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)

        userDocRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }

            if let data = snapshot?.data(), let waitlistNumber = data["waitlistNumber"] as? Int {
                DispatchQueue.main.async {
                    self?.waitlistNumber = waitlistNumber
                }
            } else {
                print("Waitlist number not found in user document.")
            }
        }
    }

    func submitReferralCode() async {
        guard !referralCode.isEmpty else {
            showAlert(title: "Invalid Code", message: "Please enter a referral code.")
            return
        }

        isSubmitting = true
        
        // Ensure referral code is lowercase before submission
        let lowercaseCode = referralCode.lowercased()

        do {
            // Validate the referral code (already lowercase)
            let isValid = try await validateReferralCode(lowercaseCode)

            if isValid {
                // Update the user's `referredBy` field
                try await updateUserReferredBy()

                // Optionally, move the user up the waitlist
                try await adjustWaitlistPosition()

                // Update the user session
                try await AuthService.shared.updateUserSession()

                // Navigate to the next view
                DispatchQueue.main.async {
                    self.navigateToNextView = true
                }
            } else {
                showAlert(title: "Invalid Code", message: "The referral code you entered is invalid.")
            }
        } catch {
            print("Error validating referral code: \(error)")
            showAlert(title: "Error", message: "An error occurred while validating the referral code.")
        }

        DispatchQueue.main.async {
            self.isSubmitting = false
        }
    }

    private func validateReferralCode(_ code: String) async throws -> Bool {
        let db = Firestore.firestore()
        let usersRef = db.collection("users")
        // Query with lowercase code
        let querySnapshot = try await usersRef.whereField("referralCode", isEqualTo: code.lowercased()).getDocuments()

        if let referredByUser = querySnapshot.documents.first {
            // Update the `totalReferrals` of the referring user
            let referredByUserId = referredByUser.documentID
            return true
        }

        return false
    }

    private func updateUserReferredBy() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)

        // Store the lowercase version of the referral code
        try await userDocRef.updateData([
            "referredBy": String(referralCode.lowercased().dropLast(3))
        ])
    }

    private func adjustWaitlistPosition() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)

        let currentWaitlistNumber = await getCurrentWaitlistNumber() ?? 1
        let newWaitlistNumber = 0

        try await userDocRef.updateData([
            "waitlistNumber": newWaitlistNumber
        ])
    }

    private func getCurrentWaitlistNumber() async -> Int? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(userId)
        let document = try? await userDocRef.getDocument()
        return document?.data()?["waitlistNumber"] as? Int
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct InfiniteCheckersView: View {
    @State private var phase: CGFloat = 0
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            HStack(spacing: 0) {
                // We use two images to create the infinite scroll effect
                Image("checkers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
                
                Image("checkers")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width)
            }
            .offset(x: phase)
            .onReceive(timer) { _ in
                // Adjust speed by changing the phase increment
                phase -= 0.2 // Decrease for faster movement, increase for slower
                
                // Reset phase when it exceeds one full width
                if abs(phase) >= width {
                    phase = 0
                }
            }
        }
        .frame(maxWidth: .infinity)
        .clipped() // Ensures content outside the frame is hidden
    }
}
