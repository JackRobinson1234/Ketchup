//
//  ProfileReportView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/12/24.
//

import SwiftUI
import FirebaseAuth

struct ProfileOptionsSheet: View {
    let user: User
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    @State var isReported: Bool = false
    @State private var isUserBlocked: Bool = false
    @State private var showBlockAlert: Bool = false
    @State private var showUnblockAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button {
                showReportDetails = true
            } label: {
                Text("Report Profile")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.black)
                    .bold()
            }
            
            Button {
                if isUserBlocked {
                    showUnblockAlert = true
                } else {
                    showBlockAlert = true
                }
            } label: {
                Text(isUserBlocked ? "Unblock User" : "Block User")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.black)
                    .bold()
            }
        }
        .onChange(of: optionsSheetDismissed) { newValue in
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .onAppear {
            if optionsSheetDismissed {
                dismiss()
            }
            checkIfUserIsBlocked()
        }
        .padding()
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: user.id, objectType: "profile", isReported: $isReported, dismissView: $optionsSheetDismissed)
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                .onDisappear{
                    dismiss()
                }
        }
        .alert("Block User", isPresented: $showBlockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Block", role: .destructive) {
                blockUser()
            }
        } message: {
            Text("Are you sure you want to block this user? You won't see their content and they won't be able to interact with you.")
        }
        .alert("Unblock User", isPresented: $showUnblockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unblock") {
                unblockUser()
            }
        } message: {
            Text("Are you sure you want to unblock this user? You'll be able to see their content and they'll be able to interact with you again.")
        }
    }
    
    private func checkIfUserIsBlocked() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        UserService.shared.isUserBlocked(currentUserId: currentUserId, blockedUserId: user.id) { result in
            switch result {
            case .success(let isBlocked):
                self.isUserBlocked = isBlocked
            case .failure(let error):
                print("Error checking if user is blocked: \(error.localizedDescription)")
            }
        }
    }
    
    private func blockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        UserService.shared.blockUser(currentUserId: currentUserId, userToBlockId: user.id) { result in
            switch result {
            case .success:
                self.isUserBlocked = true
                //print("User blocked successfully")
            case .failure(let error):
             print("Error blocking user: \(error.localizedDescription)")
            }
        }
    }
    
    private func unblockUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        UserService.shared.unblockUser(currentUserId: currentUserId, userToUnblockId: user.id) { result in
            switch result {
            case .success:
                self.isUserBlocked = false
                //print("User unblocked successfully")
            case .failure(let error):
                print("Error unblocking user: \(error.localizedDescription)")
            }
        }
    }
}
