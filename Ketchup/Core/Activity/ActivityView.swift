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
    @State var showSearchView: Bool = false
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .onAppear {
                            Task {
                                viewModel.user = AuthService.shared.userSession
                                try? await viewModel.fetchInitialActivities()
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
                                    .padding(8)
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
                                    .padding(8)
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
                        Button{
                            showSearchView.toggle()
                        } label:
                        {
                            Text("Find your friends!")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundStyle(Color("Colors/AccentColor"))
                        }
                        Divider()
                        // MARK: Friends
                        activityList
                    }
                }
            }
            .onChange(of: viewModel.letsKetchupOption) {
                Task {
                    try? await viewModel.fetchInitialActivities()
                }
            }
            .navigationTitle("Let's Ketchup!")
            .refreshable {
                Task {
                    try? await viewModel.fetchInitialActivities()
                }
            }
            .fullScreenCover(isPresented: $showSearchView) {
                SearchView()
            }
        }
    }
    @ViewBuilder
    var activityList: some View {
        let activities = viewModel.letsKetchupOption == .friends ? viewModel.friendsActivity : viewModel.trendingActivity
        if !activities.isEmpty {
            ScrollView (showsIndicators: false){
                LazyVStack {
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        ActivityCell(activity: activity, viewModel: viewModel)
                            .onAppear {
                                Task {
                                    await viewModel.fetchMoreActivities(currentIndex: index)
                                }
                            }
                    }
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
        } else {
            if viewModel.isFetching {
                ProgressView()
            } else {
                VStack{
                    Text(viewModel.letsKetchupOption == .friends ? "Your friends don't have any recent activity!" : "There is no Global activity")
                    Spacer()
                }
            }
        }
    }
}


#Preview {
    ActivityView()
}
