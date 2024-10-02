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
    @Binding var selectedBadge: Badge?
    @Binding var selectedBadgeType: BadgeType?  // Binding to the selected badge type

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Basic Badges Section
                SectionHeaderView(title: "Basic Badges", badgeType: .basic, onInfoTap: { badgeType in
                    self.selectedBadgeType = badgeType  // Set the selected badge type
                })
                BadgeGridView(badges: badgesForType(.basic) ?? [], onBadgeTap: { badge in
                    self.selectedBadge = badge
                })

                // Advanced Badges Section
                SectionHeaderView(title: "Advanced Badges", badgeType: .advanced, onInfoTap: { badgeType in
                    self.selectedBadgeType = badgeType
                })
                BadgeGridView(badges: badgesForType(.advanced) ?? [], onBadgeTap: { badge in
                    self.selectedBadge = badge
                })

                // Limited Badges Section
                SectionHeaderView(title: "Limited Badges", badgeType: .limited, onInfoTap: { badgeType in
                    self.selectedBadgeType = badgeType
                })
                BadgeGridView(badges: badgesForType(.limited) ?? [], onBadgeTap: { badge in
                    self.selectedBadge = badge
                })
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

    private func badgesForType(_ type: BadgeType) -> [Badge]? {
        let filteredBadges = badges.filter { $0.type == type }
        if filteredBadges.isEmpty { return nil }
        let sortedBadges = filteredBadges.sorted { $0.tier > $1.tier }
        return sortedBadges
    }
    
}

struct SectionHeaderView: View {
    var title: String
    var badgeType: BadgeType
    var onInfoTap: (BadgeType) -> Void  // Closure to handle info button tap

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("MuseoSansRounded-300", size: 25))
                .bold()
                .padding(.leading)

            Button(action: {
                onInfoTap(badgeType)  // Call the closure with the badge type
            }) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.custom("MuseoSansRounded-300", size: 20))
                    .foregroundColor(.black)
                    .opacity(0.3)
            }
        }
    }
}


struct BadgeGridView: View {
    var badges: [Badge]
    var onBadgeTap: (Badge) -> Void  // Closure to handle badge tap
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
                    HStack {
                        Text(badge.name)
                            .font(.custom("MuseoSansRounded-300", size: 15))
                            .opacity(badge.tier == .locked ? 0.10 : 1.0)
                            .multilineTextAlignment(.center)
                            .bold()
                    }
                    
                    Image(badge.imageName) // Load image from assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .opacity(badge.tier == .locked ? 0.05 : 1.0) // Set opacity
                        .shadow(color: badge.backgroundColor, radius: 10, x: 0, y: 0)
                    
                    // Progress bar
                    if let totalProgress = calculateTotalProgress(badge: badge) {
                        ProgressView(value: totalProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: totalProgress >= 1.0 ? .green : Color("Colors/AccentColor")))
                            .frame(width: 40, height: 4)
                    }
                }
                .padding(.bottom)
                .onTapGesture {
                    // Call the closure when a badge is tapped
                    self.onBadgeTap(badge)
                }
            }
        }
    }
    
    // Helper function to calculate total progress for the badge
    private func calculateTotalProgress(badge: Badge) -> Double? {
        let totalRequired = badge.progress.map { $0.required }.reduce(0, +)
        let totalCurrent = badge.progress.map { $0.current }.reduce(0, +)
        
        guard totalRequired > 0 else { return nil }
        
        return Double(totalCurrent) / Double(totalRequired)
    }
    
    // Helper function to determine if the badge is complete
    private func isBadgeComplete(badge: Badge) -> Bool {
        guard let totalProgress = calculateTotalProgress(badge: badge) else {
            return false
        }
        return totalProgress >= 1.0
    }
}

struct BadgeDetailView: View {
    var badge: Badge
    var onDismiss: () -> Void  // Closure to dismiss the popup
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .padding([.top, .trailing])
                }
                
                // Badge name with green checkmark if complete
                HStack {
                    Text(badge.name)
                        .font(.custom("MuseoSansRounded-300", size: 30))
                        .bold()
                        .opacity(badge.tier == .locked ? 0.10 : 1.0)
                        .padding(.horizontal)
                }
              
                
                
                // Badge image
                Image(badge.imageName) // Use the image name from your asset catalog
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .opacity(badge.tier == .locked ? 0.05 : 1.0) // Set opacity
                    .shadow(color: badge.backgroundColor, radius: 10, x: 0, y: 0)
                    .padding()
                
                HStack {
                    Text("Tier:")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .multilineTextAlignment(.leading)
                        .bold()
                    
                    Text(badge.tier.displayName)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(badge.textColor)
                        .multilineTextAlignment(.leading)
                        .bold()
                    
                    Spacer()
                }
                .padding(.leading)
                
                // Badge description
                HStack {
                    Text(badge.description)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil) // Allow unlimited lines
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // Exact progress
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(badge.progress, id: \.task) { progressItem in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(progressItem.task)
                                    .font(.custom("MuseoSansRounded-300", size: 14))
                                
                                Spacer()
                                
                                // Add green checkmark if progress is complete
                                if progressItem.current >= progressItem.required {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            ProgressView(value: Double(progressItem.current) / Double(progressItem.required))
                                .progressViewStyle(LinearProgressViewStyle(tint: progressItem.current >= progressItem.required ? .green : Color("Colors/AccentColor")))
                            Text("\(progressItem.current) / \(progressItem.required)")
                                .font(.custom("MuseoSansRounded-300", size: 14))
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    // Helper function to determine if the badge is complete
    private func isBadgeComplete(badge: Badge) -> Bool {
        let isComplete = badge.progress.allSatisfy { progressItem in
            progressItem.current >= progressItem.required
        }
        return isComplete
    }
}

struct BadgeTypeInfoView: View {
    var badgeType: BadgeType
    var onDismiss: () -> Void  // Closure to dismiss the popup

    var body: some View {
        VStack(alignment: .leading) {  // Align all content to the leading edge
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .padding([.top, .trailing])
            }

            // Title
            Text(badgeTypeTitle())
                .font(.custom("MuseoSansRounded-300", size: 25))
                .bold()
                .padding(.bottom, 8)
                .padding(.horizontal)

            // Description
            Text(badgeTypeDescription())
                .font(.custom("MuseoSansRounded-300", size: 18))
                .multilineTextAlignment(.leading)
                .padding(.horizontal)

            // Notes
            if let notes = badgeTypeNotes() {
                Text(notes)
                    .font(.custom("MuseoSansRounded-300", size: 14))  // Make font size a bit closer to the description
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)  // Match padding with description
                    .padding(.top, 4)      // Add a bit of spacing between the description and notes
            }

            Spacer()
        }
        .padding(.bottom)  // General padding to give space at the bottom
    }

    // Helper functions to get title and description based on badge type
    func badgeTypeTitle() -> String {
        switch badgeType {
        case .basic:
            return "Basic Badges"
        case .advanced:
            return "Advanced Badges"
        case .limited:
            return "Limited Badges"
        }
    }

    func badgeTypeDescription() -> String {
        switch badgeType {
        case .basic:
            return "Basic Badges may seem easy, but don’t be fooled! With 4 different tiers—Bronze, Silver, Gold, and Diamond—these badges start simple but climb to serious prestige."
        case .advanced:
            return "Advanced Badges are for those who love a good challenge. These are awarded for difficult, one-time feats. No tiers here—just pure bragging rights once you’ve conquered the task. Unlock it, own it, flaunt it forever!"
        case .limited:
            return "Limited Badges are the hardest to obtain and the most exclusive badges out there. Available only for a short time, these rare treasures are earned by attending exclusive events or tackling special in-app challenges. Once they're gone, they’re gone—so grab them while you can!"
        }
    }

    // Helper function to get notes based on badge type
    func badgeTypeNotes() -> String? {
        switch badgeType {
        case .basic:
            return "Progress towards tiers can only be made once unlocked."
        case .advanced:
            return nil // No notes for advanced badges
        case .limited:
            return "Only badges you've unlocked and currently available limited badges will appear here."
        }
    }
}










