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
import FirebaseAuth

struct ContactsView: View {
    @StateObject private var viewModel: ContactsViewModel
    @State private var searchText = ""
    @State private var isContactsPermissionDenied = false
    @State private var isSyncingContacts = false
    @State private var showMessageComposer = false
    @State private var showCopiedAlert = false
    
    init(shouldFetchExistingUsers: Bool = true) {
        _viewModel = StateObject(wrappedValue: ContactsViewModel(shouldFetchExistingUsers: shouldFetchExistingUsers))
    }
    var body: some View {
        NavigationView {
            VStack{
                Text("Your referral code: \(AuthService.shared.userSession?.referralCode ?? "ketchup583")")
                    .font(.custom("MuseoSansRounded-700", size: 14))
                    .foregroundStyle(.black)
                ZStack {
                    if ContactService.shared.isSyncing {
                        VStack {
                            FastCrossfadeFoodImageView()
                            Text("Loading contacts- please check in soon")
                        }
                    } else if isContactsPermissionDenied {
                        deniedPermissionView
                    } else if viewModel.contacts.isEmpty && !viewModel.isLoading && !viewModel.isLoadingExistingUsers {
                        emptyView
                    } else {
                        VStack {
                            
                            contactsList
                            if viewModel.isLoadingExistingUsers {
                                FastCrossfadeFoodImageView()
                                
                            }
                        }
                    }
                }
            }
            .alert(isPresented: $showCopiedAlert) {
                Alert(title: Text("Copied!"), message: Text("Invite link copied to clipboard"), dismissButton: .default(Text("OK")))
            }
            .navigationBarItems(trailing: copyInviteLinkButton)
            .navigationTitle("Friends on Ketchup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkContactsPermissionAndSync()
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.error.map { AlertItem(error: $0) } },
                set: { _ in viewModel.error = nil }
            )) { alertItem in
                Alert(title: Text("Error"), message: Text(alertItem.error.localizedDescription))
            }
            .modifier(BackButtonModifier())
            .sheet(isPresented: $showMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    ContactMessageComposeView(
                        isShowing: $showMessageComposer,
                        recipient: viewModel.messageRecipient ?? "",
                        body: inviteMessage
                    )
                } else {
                    Text("This device cannot send text messages")
                }
            }
        }
    }
    
    private var contactsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack {
                ForEach(filteredContacts) { contact in
                    ContactRow(viewModel: viewModel, contact: contact)
                        .padding(.horizontal)
                        .onAppear {
                            // Check if this is the last item and pagination is needed
                            if contact == filteredContacts.last && viewModel.hasMoreContacts && !viewModel.isLoading {
                                viewModel.fetchContacts()
                            }
                        }
                }
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }
    private var copyInviteLinkButton: some View {
        Button(action: copyInviteLink) {
            VStack{
                Image(systemName: "link")
                    .foregroundColor(Color("Colors/AccentColor"))
                if !showCopiedAlert{
                    Text("Copy Link")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundStyle(.black)
                } else {
                    Text("Copied!")
                        .font(.custom("MuseoSansRounded-500", size: 12))
                        .foregroundStyle(.black)
                }
            }
        }
    }
    private func copyInviteLink() {
        UIPasteboard.general.string = inviteMessage
        showCopiedAlert = true
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
            inviteButton
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
            inviteButton
        }
    }
    
    private var inviteButton: some View {
        Button(action: {
            showMessageComposer = true
        }) {
            Text("Ketchup is Invite Only!")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color("Colors/AccentColor"))
                .cornerRadius(8)
                .padding(.top, 20)
        }
    }
    
    var inviteMessage: String {
        let appStoreLink = "https://ketchup-app.com/open"
        
        return """
        Hey! Here's my invite for Ketchup to share your restaurant reviews. It's invite only right now, use my code:
                   
        \(AuthService.shared.userSession?.referralCode ?? "ketchup583")
                   
        here is the download link:

        \(appStoreLink)
        """
        
    }
    
    // Other view components (contactsList, filteredContacts) remain unchanged
    
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
        if AuthService.shared.userSession?.contactsSynced == false {
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
}

struct ContactRow: View {
    @ObservedObject var viewModel: ContactsViewModel
    @State var contact: Contact
    @State private var isFollowed: Bool
    @State private var isCheckingFollowStatus: Bool = false
    @State private var hasCheckedFollowStatus: Bool = false
    @State private var isShowingProfile: Bool = false // Local state for showing the profile
    @State private var isShowingMessageComposer = false
    
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
            } else {
                UserCircularProfileImageView(profileImageUrl: contact.user?.profileImageUrl, size: .small)
            }
        
            
            VStack(alignment: .leading, spacing: 1) {
                if let hasExistingAccount = contact.hasExistingAccount, hasExistingAccount {
                    Button(action: {
                        isShowingProfile = true
                    }) {
                        Text(contact.user?.fullname ?? contact.deviceContactName ?? "unknown")
                            .font(.custom("MuseoSansRounded-500", size: 14))
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
                   // locationText
                } else {
                    Text(contact.deviceContactName ?? "unknown")
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .foregroundStyle(.black)
                    
                    Text("\(contact.userCount) friends on Ketchup")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let hasExistingAccount = contact.hasExistingAccount, hasExistingAccount {
                if isCheckingFollowStatus {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if contact.user?.id != Auth.auth().currentUser?.uid {
                    followButton
                }
            } else {
                inviteButton
            }
        }
        .padding(.vertical, 8)
        .onAppear(perform: checkFollowStatus)
        .sheet(isPresented: $isShowingMessageComposer) {
            if MFMessageComposeViewController.canSendText() {
                if let deviceContactNumber = contact.deviceContactNumber{
                    ContactMessageComposeView(
                        isShowing: $isShowingMessageComposer,
                        recipient: deviceContactNumber,
                        body: viewModel.inviteMessage
                    )
                } else {
                    Text("Error finding phone number")
                }
            } else {
                Text("This device cannot send text messages")
            }
        }
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
                ////print("Error checking follow status: \(error.localizedDescription)")
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
                ////print("Failed to follow/unfollow: \(error.localizedDescription)")
            }
        }
    }
    
    private var followButton: some View {
        Button(action: handleFollowAction) {
            Text(isFollowed ? "Following" : "Follow")
                .font(.custom("MuseoSansRounded-300", size: 14))
                .fontWeight(.semibold)
                .frame(width: 100)
                .padding(.vertical, 6)
                .foregroundColor(isFollowed ? Color("Colors/AccentColor") : .white)
                .background(isFollowed ? Color.clear : Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("Colors/AccentColor"), lineWidth: isFollowed ? 1 : 0)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())  // Ensures only the button area is tappable
    }
    
    private var inviteButton: some View {
        Button(action: {
            isShowingMessageComposer = true
        }) {
            Text("Invite")
                .font(.custom("MuseoSansRounded-300", size: 14))
                .fontWeight(.semibold)
                .frame(width: 100)
                .padding(.vertical, 8)
                .foregroundColor(Color("Colors/AccentColor"))
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}
struct AlertItem: Identifiable {
    let id = UUID()
    let error: Error
}
