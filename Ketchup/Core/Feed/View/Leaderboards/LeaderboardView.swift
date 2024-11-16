//
//  LeaderboardView.swift
//  Ketchup
//
//  Created by Jack Robinson on 11/15/24.
//

import SwiftUI
import FirebaseFirestoreInternal

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @State private var selectedTab = 0
    @State private var selectedLocation: String?
    
    private let tabs = ["Been", "Influence", "Notes", "Photos"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(Array(tabs.enumerated()), id: \.element) { index, tab in
                            Button(action: { selectedTab = index }) {
                                Text(tab)
                                    .font(.custom("MuseoSansRounded-500", size: 16))
                                    .foregroundColor(selectedTab == index ? .black : .gray)
                                    .padding(.bottom, 8)
                                    .overlay(
                                        Rectangle()
                                            .frame(height: 2)
                                            .foregroundColor(selectedTab == index ? .black : .clear)
                                            .offset(y: 4)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Description Text
                Text("Number of places on your been list")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.gray)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // Filters
                HStack(spacing: 12) {
                    Menu {
                        Button("All Members") { selectedLocation = nil }
                        // Add other member filter options
                    } label: {
                        HStack {
                            Text(selectedLocation == nil ? "All Members" : "Selected")
                                .font(.custom("MuseoSansRounded-500", size: 14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    }
                    
                    Menu {
                        Button("Los Angeles, CA") { selectedLocation = "Los Angeles, CA" }
                        // Add other location options
                    } label: {
                        HStack {
                            Text(selectedLocation ?? "Select Location")
                                .font(.custom("MuseoSansRounded-500", size: 14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 16)
                
                // Leaderboard List
                if viewModel.users.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emptyView: some View {
        VStack {
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("No Users Found")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
        }
    }
    
    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.users.enumerated()), id: \.element.id) { index, user in
                    LeaderboardRow(rank: index + 1, user: user)
                    
                    if index < viewModel.users.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
                
                if viewModel.hasMoreUsers {
                    ProgressView()
                        .padding()
                        .onAppear {
                            viewModel.fetchUsers()
                        }
                }
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.custom("MuseoSansRounded-700", size: 16))
                .frame(width: 30)
                .foregroundColor(.gray)
            
            NavigationLink(destination: ProfileView(uid: user.id)) {
                HStack {
                    UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if user.username.hasPrefix("@") {
                            Text(user.username)
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .foregroundStyle(.black)
                        } else {
                            Text(user.fullname)
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .foregroundStyle(.black)
                            
                            Text("@\(user.username)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Score
            Text("\(user.stats.posts)")
                .font(.custom("MuseoSansRounded-700", size: 18))
                .foregroundColor(.black)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var hasMoreUsers = true
    @Published var error: Error?
    
    private var lastDocument: QueryDocumentSnapshot?
    private let limit = 20
    
    func fetchUsers() {
        guard !isLoading, hasMoreUsers else { return }
        isLoading = true
        
        let query = Firestore.firestore().collection("users")
            .order(by: "stats.posts", descending: true)
            .limit(to: limit)
        
        if let last = lastDocument {
            query.start(afterDocument: last)
        }
        
        Task {
            do {
                let snapshot = try await query.getDocuments()
                DispatchQueue.main.async {
                    let newUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
                    self.users.append(contentsOf: newUsers)
                    self.lastDocument = snapshot.documents.last
                    self.hasMoreUsers = !snapshot.documents.isEmpty && snapshot.documents.count == self.limit
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}
