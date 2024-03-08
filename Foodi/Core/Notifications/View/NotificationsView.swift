//
//  NotificationsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = NotificationsViewModel(service: NotificationService())
    private let userService: UserService
    init(userService: UserService){
        self.userService = userService
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.notifications) { notification in
                        NotificationCell(notification: notification)
                            .padding(.top)
                    }
                }

            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await viewModel.fetchNotifications() }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.showEmptyView {
                    ContentUnavailableView("No notifications to show", systemImage: "bubble.middle.bottom")
                        .foregroundStyle(.gray)
                }
            }
            //.navigationDestination(for: notification.postId): {
            .navigationDestination(for: User.self, destination: {user in
                ProfileView(uid: user.id, userService: userService)})
            .navigationDestination(for: SearchModelConfig.self) { config in
                SearchView(userService: UserService(), searchConfig: config)}
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                            .padding()
                    }
                }
            }

        }
    }
    
}

#Preview {
    NotificationsView(userService: UserService())
}
