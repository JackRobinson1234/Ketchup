//
//  NotificationsView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//
import SwiftUI
struct NotificationsView: View {
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = NotificationsViewModel(service: NotificationService())
    @State var dragDirection = "left"
    @State var isDragging = false
    @StateObject var feedViewModel = FeedViewModel()
    var drag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    isPresented = false
                    dismiss()
                }
            }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.notifications) { notification in
                        NotificationCell(viewModel: viewModel, notification: notification, feedViewModel: feedViewModel)
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
            .navigationDestination(for: User.self, destination: { user in
                ProfileView(uid: user.id)
            })
            
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresented = false
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.black)
                            .padding()
                    }
                }
            }
          
        }
        .gesture(drag)
        .onAppear {
            Task{
                try await clearNotificationAlerts()
            }
        }
    }
    
    private func clearNotificationAlerts() async throws {
        do {
            AuthService.shared.userSession?.notificationAlert = 0
            try await UserService.shared.clearNotificationAlert()
        } catch {
            print("Error clearing notification alert")
        }
    }
}


