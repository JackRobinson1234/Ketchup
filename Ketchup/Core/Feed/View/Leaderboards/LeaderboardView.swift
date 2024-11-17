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
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.users.isEmpty && !viewModel.isLoading {
                    emptyView
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if viewModel.users.isEmpty {
                    viewModel.fetchUsers()
                }
            }
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
        List {
            ForEach(Array(viewModel.users.enumerated()), id: \.element.id) { index, user in
                LeaderboardRow(rank: index + 1, user: user)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            
            if viewModel.hasMoreUsers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .onAppear {
                        viewModel.fetchUsers()
                    }
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            viewModel.refresh()
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
            
            // Points
            Text("\(user.totalPoints)")
                .font(.custom("MuseoSansRounded-700", size: 18))
                .foregroundColor(.black)
        }
        .padding(.vertical, 12)
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var hasMoreUsers = true
    @Published var error: Error?
    
    private var lastDocument: QueryDocumentSnapshot?
    private let limit = 20
    
    func refresh() {
        users.removeAll()
        lastDocument = nil
        hasMoreUsers = true
        fetchUsers()
    }
    
    func fetchUsers() {
        guard !isLoading, hasMoreUsers else { return }
        isLoading = true
        
        let query: Query
        if let last = lastDocument {
            query = Firestore.firestore().collection("users")
                .order(by: "totalPoints", descending: true)
                .limit(to: limit)
                .start(afterDocument: last)
        } else {
            query = Firestore.firestore().collection("users")
                .order(by: "totalPoints", descending: true)
                .limit(to: limit)
        }
        
        Task {
            do {
                let snapshot = try await query.getDocuments()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let newUsers = snapshot.documents.compactMap { try? $0.data(as: User.self) }
                    self.users.append(contentsOf: newUsers)
                    self.lastDocument = snapshot.documents.last
                    self.hasMoreUsers = !snapshot.documents.isEmpty && snapshot.documents.count == self.limit
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.error = error
                    self?.isLoading = false
                }
            }
        }
    }
}
