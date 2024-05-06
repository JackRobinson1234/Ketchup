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
                                    //try await viewModel.fetchKetchupActivities()
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
                                    ForEach(viewModel.friendsActivity) { activity in
                                        ActivityCell(activity: activity, viewModel: viewModel)
                                    }
                                    //MARK: Ketchup
                                }
                            } else {
                                Spacer()
                                Text("Your friends don't have any recent activity!")
                                Spacer()
                            }
                        }
                        //MARK: Trendinjg
                        else if viewModel.letsKetchupOption == .trending {
                            if !viewModel.trendingActivity.isEmpty {
                                ScrollView{
                                    ForEach(viewModel.trendingActivity) { activity in
                                        ActivityCell(activity: activity, viewModel: viewModel)
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
                Task{
                    try await viewModel.fetchActivitiesIfNeeded()
                }
            }
            .navigationTitle("Let's Ketchup!")
            .refreshable{
                if viewModel.letsKetchupOption == .trending {
                    Task{
                        try await viewModel.fetchTrendingActivities()
                    }
                } else if viewModel.letsKetchupOption == .friends {
                    Task{
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
