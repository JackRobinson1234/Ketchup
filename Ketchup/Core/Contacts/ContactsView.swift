//
//  ContactsView.swift
//  Ketchup
//
//  Created by Jack Robinson on 8/17/24.
//
import SwiftUI
import Contacts
import ContactsUI
import Kingfisher
import MessageUI

struct ContactsView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var searchText = ""
    @State private var isContactsPermissionDenied = false // State to track if permission is denied
    @State private var isSyncingContacts = false
    var body: some View {
        NavigationView {
            ZStack {
                if ContactService.shared.isSyncing {
                    VStack{
                        FastCrossfadeFoodImageView()
                        Text("Loading contacts- please check in soon")
                    }
                } else if isContactsPermissionDenied {
                    deniedPermissionView
                } else if viewModel.contacts.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    contactsList
                }
            }

            .navigationTitle("Contacts on Ketchup")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .onAppear {
                checkContactsPermissionAndSync()
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem(error: $0) } },
                set: { _ in viewModel.error = nil }
            )) { alertItem in
                Alert(title: Text("Error"), message: Text(alertItem.error.localizedDescription))
            }
            .sheet(isPresented: $viewModel.isShowingMessageComposer) {
                if let username = AuthService.shared.userSession?.username{
                    if MFMessageComposeViewController.canSendText() {
                        ContactMessageComposeView(
                            isShowing: $viewModel.isShowingMessageComposer,
                            recipient: viewModel.messageRecipient ?? "",
                            body: "Hey! Sharing an invite to the beta for Ketchup - a social restaurant rating app. I think you would love it and selfishly I want you on the app so I can see where you eat at. Use this link to get on: https://testflight.apple.com/join/ki6ajEz9  (P.S. Follow me @\(username))"
                        )
                    }
                } else {
                    Text("This device cannot send text messages")
                }
            }
            
        }
    }
    private var deniedPermissionView: some View {
        VStack {
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("Contacts Permission Denied")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("Please allow access to your contacts in Settings to find your friends on Ketchup.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 4)
            Button(action: openSettings) {
                Text("Go to Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("Colors/AccentColor"))
                    .cornerRadius(8)
                    .padding(.top, 20)
            }
        }
        .padding()
    }
    private var emptyView: some View {
        VStack {
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("No Contacts Found on App")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
            Text("Invite your contacts to join the app!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 4)
        }
    }
    
    private var contactsList: some View {
        List {
            ForEach(filteredContacts.filter { $0.hasExistingAccount == true }) { contact in
                ContactRow(viewModel: viewModel, contact: contact)
            }
            
            
            
            /* ForEach(filteredContacts.filter { $0.hasExistingAccount == false }) {*/
            ForEach(filteredContacts.filter { $0.hasExistingAccount == false || $0.hasExistingAccount == nil }) { contact in
                ContactRow(viewModel: viewModel, contact: contact)
            }
            
            if viewModel.hasMoreContacts {
                ProgressView()
                    .onAppear {
                        viewModel.fetchContacts()
                    }
            }
            
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return viewModel.contacts
        } else {
            return viewModel.contacts.filter { contact in
                contact.phoneNumber.contains(searchText) ||
                (contact.user?.username.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }
    private func checkContactsPermissionAndSync() {
           let authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
           if authorizationStatus == .denied || authorizationStatus == .restricted {
               isContactsPermissionDenied = true
           } else if authorizationStatus == .notDetermined {
               CNContactStore().requestAccess(for: .contacts) { granted, _ in
                   DispatchQueue.main.async {
                       isContactsPermissionDenied = !granted
                       if granted {
                           startContactSync()
                       }
                   }
               }
           } else if authorizationStatus == .authorized {
               startContactSync()
           }
       }
       
       private func startContactSync() {
           if AuthService.shared.userSession?.hasContactsSynced == false {
               isSyncingContacts = true
               Task {
                   try await ContactService.shared.syncDeviceContacts()
                   viewModel.fetchContacts()
                   isSyncingContacts = false
               }
           } else {
               viewModel.fetchContacts()
           }
       }
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

struct ContactRow: View {
    @ObservedObject var viewModel: ContactsViewModel
    @State var contact: Contact
    @State private var isFollowed: Bool
    @State private var isCheckingFollowStatus: Bool = false
    @State private var hasCheckedFollowStatus: Bool = false
    @State private var isShowingProfile: Bool = false // Local state for showing the profile

    init(viewModel: ContactsViewModel, contact: Contact) {
        self.viewModel = viewModel
        self._contact = State(initialValue: contact)
        self._isFollowed = State(initialValue: contact.isFollowed ?? false)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let hasExistingAccount = contact.hasExistingAccount, hasExistingAccount {
                Button(action: {
                    isShowingProfile = true
                }) {
                    UserCircularProfileImageView(profileImageUrl: contact.user?.profileImageUrl, size: .small)
                }
                .fullScreenCover(isPresented: $isShowingProfile) {
                    if let userId = contact.user?.id {
                        NavigationStack {
                            ProfileView(uid: userId)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let hasExistingAccount = contact.hasExistingAccount, hasExistingAccount {
                    Button(action: {
                        isShowingProfile = true
                    }) {
                        Text(contact.user?.fullname ?? contact.deviceContactName ?? contact.phoneNumber)
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(.black)
                    }
                    .fullScreenCover(isPresented: $isShowingProfile) {
                        if let userId = contact.user?.id {
                            NavigationStack {
                                ProfileView(uid: userId)
                            }
                        }
                    }
                    
                    if let username = contact.user?.username {
                        Text("@\(username)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    locationText
                } else {
                    Text(contact.deviceContactName ?? contact.phoneNumber)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .foregroundStyle(.black)
                    
                    Text("\(contact.userCount) friends on Ketchup")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let hasExistingAccount = contact.hasExistingAccount, hasExistingAccount {
                if isCheckingFollowStatus {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    followButton
                }
            } else {
                inviteButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
    }
    
    private var locationText: some View {
        Text(locationString)
            .font(.system(size: 12))
            .foregroundColor(.gray)
    }
    
    private var locationString: String {
        if let city = contact.user?.location?.city, let state = contact.user?.location?.state {
            return "\(city), \(state)"
        } else if let city = contact.user?.location?.city {
            return city
        } else if let state = contact.user?.location?.state {
            return state
        } else {
            return "Location not available"
        }
    }
    
    private func checkFollowStatus() {
        guard let userId = contact.user?.id,
              let hasExistingAccount = contact.hasExistingAccount,
              hasExistingAccount,
              !hasCheckedFollowStatus else { return }
        
        isCheckingFollowStatus = true
        Task {
            do {
                isFollowed = try await viewModel.checkIfUserIsFollowed(contact: contact)
                isCheckingFollowStatus = false
                hasCheckedFollowStatus = true
            } catch {
                print("Error checking follow status: \(error.localizedDescription)")
                isCheckingFollowStatus = false
            }
        }
    }
    
    private func handleFollowAction() {
        guard let userId = contact.user?.id else { return }
        Task {
            do {
                if isFollowed {
                    try await viewModel.unfollow(userId: userId)
                } else {
                    try await viewModel.follow(userId: userId)
                }
                isFollowed.toggle()
                viewModel.updateContactFollowStatus(contact: contact, isFollowed: isFollowed)
            } catch {
                print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
    }
    
    private var inviteButton: some View {
        Button(action: { viewModel.inviteContact(contact) }) {
            Text("Invite")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .fontWeight(.semibold)
                .frame(width: 110)
                .padding(.vertical, 8)
                .foregroundColor(Color("Colors/AccentColor"))
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}
struct AlertItem: Identifiable {
    let id = UUID()
    let error: Error
}
