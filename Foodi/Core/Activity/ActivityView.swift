//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI
enum LetsKetchupOptions{
    case friends, trending
}
struct ActivityView: View {
    @State var isLoading = true
    @StateObject var viewModel = ActivityViewModel()
    private var paginationThreshold = 5
    var body: some View {
        NavigationStack{
            VStack{
                //MARK: ProgressView
                if isLoading {
                    ProgressView()
                        .onAppear{
                            Task{
                                viewModel.user = AuthService.shared.userSession
                                if viewModel.friendsActivity.isEmpty{
                                    try await viewModel.fetchFriendsActivities()
                                }
                                isLoading = false
                            }
                        }
                } else {
                    VStack{
                        //MARK: Buttons
                        HStack(spacing: 20){
                            Button{
                                viewModel.letsKetchupOption = .friends
                            } label: {
                                Text("Friends Activity")
                            }
                            .modifier(StandardButtonModifier(width: 150))
                            
                            
                            Button{
                                viewModel.letsKetchupOption = .trending
                            } label: {
                                Text("Trending Activity")
                            }
                            .modifier(StandardButtonModifier(width: 150))
                        }
                        .padding()
                        Divider()
                        //MARK: Friends
                        if viewModel.letsKetchupOption == .friends {
                            if !viewModel.friendsActivity.isEmpty{
                                ScrollView{
                                    LazyVStack {
                                        ForEach(viewModel.friendsActivity.indices, id: \.self) { index in
                                            // Calculate distance from the end
                                            let distanceFromEnd = viewModel.friendsActivity.count - index - 1
                                            
                                            ActivityCell(activity: viewModel.friendsActivity[index], viewModel: viewModel)
                                                .onAppear {
                                                    if distanceFromEnd < paginationThreshold {
                                                        Task {
                                                            try await viewModel.fetchFriendsActivities()
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                    //MARK: Ketchup
                                }
                            } else {
                                Spacer()
                                Text("Your friends don't have any recent activity!")
                                Spacer()
                            }
                        }
                        //MARK: Trending
                        else if viewModel.letsKetchupOption == .trending {
                            if !viewModel.trendingActivity.isEmpty {
                                ScrollView{
                                    LazyVStack {
                                        ForEach(viewModel.trendingActivity.indices, id: \.self) { index in
                                            // Calculate distance from the end
                                            let distanceFromEnd = viewModel.trendingActivity.count - index - 1
                                            
                                            ActivityCell(activity: viewModel.trendingActivity[index], viewModel: viewModel)
                                                .onAppear {
                                                    if distanceFromEnd == paginationThreshold {
                                                        Task {
                                                            if !viewModel.outOfTrending {
                                                                try await viewModel.fetchTrendingActivities()
                                                            }
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                }
                                    
                            } else {
                                Spacer()
                                Text("There is no trending activity")
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
                        try await viewModel.fetchFriendsActivities()
                    }
                }
            }
            .navigationTitle("Let's Ketchup!")
            .refreshable{
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
