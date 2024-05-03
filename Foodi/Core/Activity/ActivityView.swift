//
//  ActivityView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI

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
                                //try await viewModel.fetchActivities()
                                try await viewModel.fetchCurrentUser()
                                if viewModel.activityList.isEmpty{
                                    try await viewModel.fetchKetchupActivities()
                                }
                                isLoading = false
                            }
                        }
                } else {
                    //MARK: Following
                    ScrollView{
                        ForEach(viewModel.activityList) { activity in
                            ActivityCell(activity: activity, viewModel: viewModel)
                        }
                        Text("No more following recent activity to show")
                        Divider()
                        //MARK: Ketchup
                        ForEach(viewModel.ketchupActivityList) { activity in
                            ActivityCell(activity: activity, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("Activity")
            .refreshable{
                Task{
                    if viewModel.activityList.isEmpty{
                        try await viewModel.fetchKetchupActivities()
                    }
                }
            }
        }
    }
}

#Preview {
    ActivityView()
}
