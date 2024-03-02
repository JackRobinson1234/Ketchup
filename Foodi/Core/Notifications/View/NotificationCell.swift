//
//  NotificationCell.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import Kingfisher

struct NotificationCell: View {
    @ObservedObject var viewModel: NotificationCellViewModel
    
    var notification: Notification {
        return viewModel.notification
    }
    
    var isFollowed: Bool {
        return notification.user?.isFollowed ?? false
    }
    
    init(notification: Notification) {
        self.viewModel = NotificationCellViewModel(notification: notification)
    }
    
    var body: some View {
        HStack {
            NavigationLink(value: notification.user) {
                UserCircularProfileImageView(profileImageUrl: notification.user?.profileImageUrl, size: .xSmall)
                
                HStack {
                    Text(notification.user?.username ?? "")
                        .font(.footnote)
                        .fontWeight(.semibold) +
                    
                    Text(notification.type.notificationMessage)
                        .font(.footnote) +
                    
                    Text(" \(notification.timestamp.timestampString())")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
                .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if notification.type == .follow {
                Button(action: {
                    isFollowed ? viewModel.unfollow() : viewModel.follow()
                }, label: {
                    Text(isFollowed ? "Following" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 88, height: 32)
                        .foregroundColor(isFollowed ? .black : .white)
                        .background(isFollowed ? Color(.systemGroupedBackground) : Color.pink)
                        .cornerRadius(6)
                })
            } else {
                if let post = notification.postThumbnail {
                    
                        KFImage(URL(string: post))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    NotificationCell(notification: DeveloperPreview.notifications[0])
}
