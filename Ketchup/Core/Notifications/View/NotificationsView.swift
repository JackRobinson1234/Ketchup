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
    @StateObject var collectionsViewModel = CollectionsViewModel()
    @StateObject var pollViewModel = PollViewModel()
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
                        NotificationCell(viewModel: viewModel, notification: notification, feedViewModel: feedViewModel, collectionsViewModel: collectionsViewModel, pollViewModel: pollViewModel)
                            .padding(.top)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await viewModel.fetchNotifications() }
            .overlay {
                if viewModel.isLoading {
                    FastCrossfadeFoodImageView()
                } else if viewModel.showEmptyView {
                    if #available(iOS 17, *) {
                        
                        ContentUnavailableView("No notifications to show", systemImage: "bubble.middle.bottom")
                            .foregroundStyle(.gray)
                    } else {
                        CustomUnavailableView(text: "No notifications to show",image: "bubble.middle.bottom")
                    }
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
            //print("Error clearing notification alert")
        }
    }
}
struct CustomUnavailableView: View {
    let text: String
    let image: String

    var body: some View {
        VStack(spacing: 20) {
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            Text(text)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}


