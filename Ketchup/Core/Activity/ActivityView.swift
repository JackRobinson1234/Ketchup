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
    @State var isTransitioning = false
    @StateObject var viewModel = ActivityViewModel()
    @State var showSearchView: Bool = false
    @Namespace private var animation
    
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
                            ketchupButton(for: .friends)
                            //ketchupButton(for: .trending)
                        }
                        .padding()
                        
                        Button {
                            showSearchView.toggle()
                        } label: {
                            Text("Find your friends!")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundStyle(Color("Colors/AccentColor"))
                        }
                        
                        Divider()
                        HorizontalCollectionScrollView()
                        
                        // MARK: Activity List
                        ZStack {
                            if isTransitioning {
                                ProgressView()
                                    .transition(.opacity)
                            } else {
                                activityList
                                    .transition(.asymmetric(insertion: .opacity, removal: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: isTransitioning)
                        Spacer()
                    }
                }
            }
            .onChange(of: viewModel.letsKetchupOption) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isTransitioning = true
                }
                Task {
                    // Delay to allow for smooth animation
                    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                    try? await viewModel.fetchInitialActivities()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isTransitioning = false
                    }
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
    func ketchupButton(for option: LetsKetchupOptions) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.letsKetchupOption = option
            }
        } label: {
            Text(option == .friends ? "Friends" : "Ketchup")
                .padding(8)
                .background(
                    ZStack {
                        if viewModel.letsKetchupOption == option {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("Colors/AccentColor"))
                                .matchedGeometryEffect(id: "background", in: animation)
                        }
                    }
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color("Colors/AccentColor"), lineWidth: viewModel.letsKetchupOption == option ? 0 : 2)
                )
                .foregroundColor(viewModel.letsKetchupOption == option ? .white : Color("Colors/AccentColor"))
        }
    }
    
    @ViewBuilder
    var activityList: some View {
        let activities = viewModel.letsKetchupOption == .friends ? viewModel.friendsActivity : viewModel.trendingActivity
        if !activities.isEmpty {
            ScrollView(showsIndicators: false) {
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
                VStack {
                    Text(viewModel.letsKetchupOption == .friends ? "Your friends don't have any recent activity!" : "There is no Ketchup activity")
                    Spacer()
                }
            }
        }
    }
}

