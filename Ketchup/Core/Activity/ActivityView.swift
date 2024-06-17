//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
enum LetsKetchupOptions {
    case friends, trending
}

struct ActivityView: View {
    @State var isLoading = true
    @StateObject var viewModel = ActivityViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: ProgressView
                if isLoading {
                    ProgressView()
                        .onAppear {
                            Task {
                                viewModel.user = AuthService.shared.userSession
                                if viewModel.friendsActivity.isEmpty {
                                    try await viewModel.fetchFriendsActivities()
                                }
                                isLoading = false
                            }
                        }
                } else {
                    VStack {
                        // MARK: Buttons
                        HStack(spacing: 20) {
                            Button {
                                viewModel.letsKetchupOption = .friends
                            } label: {
                                Text("Friends")
                                    .padding()
                                    .background(viewModel.letsKetchupOption == .friends ? Color("Colors/AccentColor") : Color.clear)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color("Colors/AccentColor"), lineWidth: viewModel.letsKetchupOption == .friends ? 0 : 2)
                                    )
                                    .foregroundColor(viewModel.letsKetchupOption == .friends ? .white : Color("Colors/AccentColor"))
                            }

                            Button {
                                viewModel.letsKetchupOption = .trending
                            } label: {
                                Text("Global")
                                    .padding()
                                    .background(viewModel.letsKetchupOption == .trending ? Color("Colors/AccentColor") : Color.clear)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color("Colors/AccentColor"), lineWidth: viewModel.letsKetchupOption == .trending ? 0 : 2)
                                    )
                                    .foregroundColor(viewModel.letsKetchupOption == .trending ? .white : Color("Colors/AccentColor"))
                            }
                        }
                        .padding()
                        Divider()
                        // MARK: Friends
                        if viewModel.letsKetchupOption == .friends {
                            if !viewModel.friendsActivity.isEmpty {
                                ScrollView {
                                    LazyVStack {
                                        ForEach(viewModel.friendsActivity.indices, id: \.self) { index in
                                            ActivityCell(activity: viewModel.friendsActivity[index], viewModel: viewModel)
                                        }
                                    }
                                }
                            } else {
                                Spacer()
                                Text("Your friends don't have any recent activity!")
                                Spacer()
                            }
                        }
                        // MARK: Trending
                        else if viewModel.letsKetchupOption == .trending {
                            if !viewModel.trendingActivity.isEmpty {
                                ScrollView {
                                    LazyVStack {
                                        ForEach(viewModel.trendingActivity.indices, id: \.self) { index in
                                            let distanceFromEnd = viewModel.trendingActivity.count - index - 1
                                            ActivityCell(activity: viewModel.trendingActivity[index], viewModel: viewModel)
                                                .onAppear {
                                                    Task {
                                                        if !viewModel.outOfTrending {
                                                            try await viewModel.fetchMoreTrendingActivities(distanceFromEnd: distanceFromEnd)
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                            } else {
                                Spacer()
                                Text("There is no Global activity")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.letsKetchupOption) {
                Task {
                    if viewModel.letsKetchupOption == .trending {
                        try await viewModel.fetchInitialTrendingActivities()
                    } else if viewModel.letsKetchupOption == .friends {
                        // try await viewModel.fetchFriendsActivities()
                    }
                }
            }
            .navigationTitle("Let's Ketchup!")
            .refreshable {
                Task {
                    if viewModel.letsKetchupOption == .trending {
                        try await viewModel.fetchInitialTrendingActivities()
                    } else if viewModel.letsKetchupOption == .friends {
                        try await viewModel.fetchFriendsActivities()
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityView()
}
