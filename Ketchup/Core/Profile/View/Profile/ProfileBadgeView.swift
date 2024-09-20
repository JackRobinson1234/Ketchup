//
//  ProfileBadgeView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 8/28/24.
//

import SwiftUI
import Kingfisher

struct ProfileBadgeView: View {
    var user: User  // Pass the user to fetch badges
    @State private var badges: [Badge] = []  // Use a state variable to store fetched badges

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Basic Badges Section
                SectionHeaderView(title: "Basic Badges")
                BadgeGridView(badges: badgesForType(.basic) ?? [])
                
                // Advanced Badges Section
                SectionHeaderView(title: "Advanced Badges")
                BadgeGridView(badges: badgesForType(.advanced) ?? [])
                
                // Limited Badges Section
                SectionHeaderView(title: "Limited Badges")
                BadgeGridView(badges: badgesForType(.limited) ?? [])
            }
            .onAppear {
                fetchUserBadges()
            }
        }
    }

    // Helper function to fetch badges for the current user
    private func fetchUserBadges() {
        user.fetchBadges { fetchedBadges in
            self.badges = fetchedBadges
        }
    }

    // Helper function to filter badges by type
    private func badgesForType(_ type: BadgeType) -> [Badge]? {
        let filteredBadges = badges.filter { $0.type == type }
        return filteredBadges.isEmpty ? nil : filteredBadges
    }
}

struct SectionHeaderView: View {
    var title: String

    var body: some View {
        Text(title)
            .font(.custom("MuseoSansRounded-300", size: 20))
            .bold()
            .padding(.leading)
    }
}

struct BadgeGridView: View {
    var badges: [Badge]
    
    // Define the grid layout for 3 columns
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(badges) { badge in
                VStack {
                    Text(badge.name)
                        .font(.custom("MuseoSansRounded-300", size: 15))
                        .multilineTextAlignment(.center)
                    
                    ZStack {
                        if let imageUrl = badge.imageUrl, let url = URL(string: imageUrl) {
                            KFImage(url)
                                .placeholder {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .opacity(badge.tier == .locked ? 0.15 : 1.0) // Set opacity
                        } else {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(Circle())
                                
                        }
                        
                        // Overlay lock icon if badge is locked
                        if badge.tier == .locked {
                            HStack(spacing: 1) {
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 25)
                                    .foregroundColor(.black)
                                
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 25)
                                    .foregroundColor(.black)
                                Image(systemName: "questionmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 25)
                                    .foregroundColor(.black)
                            }

                        }
                    }
                    
                    // Progress bar
                    if let totalProgress = calculateTotalProgress(badge: badge) {
                        ProgressView(value: totalProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color("Colors/AccentColor")))
                            .frame(width: 40, height: 4)
                    }
                }
                .padding()
            }
        }
    }
    
    // Calculate the total progress for the badge
    private func calculateTotalProgress(badge: Badge) -> Double? {
        let totalRequired = badge.progress.map { $0.required }.reduce(0, +)
        let totalCurrent = badge.progress.map { $0.current }.reduce(0, +)
        
        guard totalRequired > 0 else { return nil }
        
        return Double(totalCurrent) / Double(totalRequired)
    }
}











