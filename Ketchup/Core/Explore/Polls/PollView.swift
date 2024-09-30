//
//  PollView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/11/24.
//

import SwiftUI
import FirebaseFirestoreInternal
import Kingfisher

struct PollView: View {
    @ObservedObject var pollViewModel: PollViewModel
    @State private var showComments = false
    @State private var showChangeVoteAlert = false
    @State private var showExpiredPollAlert = false
    @State private var selectedOptionForChange: PollOption?
    
    @Binding var poll: Poll
    var isPreview: Bool = false
    var selectedImage: UIImage?
    
    init(poll: Binding<Poll>, selectedImage: UIImage? = nil, isPreview: Bool = false, pollViewModel: PollViewModel) {
        self._poll = poll
        self.pollViewModel = pollViewModel
        self.isPreview = isPreview
        self.selectedImage = selectedImage
    }
    
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    // Image handling
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 190)
                            .clipped()
                    } else if let imageUrl = poll.imageUrl, !imageUrl.isEmpty {
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 190)
                            .clipped()
                    } else {
                        // Placeholder
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image("Skip") // Replace with your placeholder image name
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .opacity(0.6)
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                    
                    // Shadow gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.black.opacity(0.3),
                            Color.black.opacity(0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 190)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Title and Date
                        HStack {
                            Text(isPreview ? "Poll Preview" : "Poll")
                                .font(.custom("MuseoSansRounded-700", size: 18))
                            if !isPreview {
                                Text("• \(formattedDate(poll.scheduledDate))")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                        
                        // Question text
                        Text(poll.question.isEmpty ? "Your question will appear here" : poll.question)
                            .foregroundColor(.white)
                            .font(.custom("MuseoSansRounded-700", size: 20))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .frame(height: 190)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(poll.options) { option in
                        let hasVotedInfo = pollViewModel.hasUserVotedPolls[poll.id]
                        let hasVoted = hasVotedInfo?.hasVoted ?? false
                        let userVotedOptionId = hasVotedInfo?.optionId
                        
                        PollOptionView(
                            option: option,
                            isSelected: userVotedOptionId == option.id,
                            totalVotes: poll.totalVotes,
                            hasVoted: hasVoted,
                            isPreview: isPreview,
                            isActive: poll.isActive,
                            action: {
                                triggerHapticFeedback()
                                selectOption(option)
                            }
                        )
                    }
                    
                    if !isPreview {
                        VStack(alignment: .leading, spacing: 4) {
                            // Interaction buttons and expiration info
                            HStack {
                                let hasVotedInfo = pollViewModel.hasUserVotedPolls[poll.id]
                                let hasVoted = hasVotedInfo?.hasVoted ?? false
                                
                                if hasVoted {
                                    Text("Total votes: \(poll.totalVotes)")
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Vote to see results")
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                Button {
                                    showComments.toggle()
                                } label: {
                                    InteractionButtonView(icon: "ellipsis.bubble", count: poll.commentCount)
                                }
                            }
                            .padding(.horizontal)
                            
                            // New live status indicator
                            HStack (spacing: 1){
                                if poll.isActive {
                                    Text("LIVE")
                                        .font(.custom("MuseoSansRounded-700", size: 12))
                                        .foregroundColor(.green)
                                    Text("(voting ends in: \(timeRemaining(until: poll.expiresAt)))")
                                        .font(.custom("MuseoSansRounded-300", size: 12))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Poll Expired")
                                        .font(.custom("MuseoSansRounded-700", size: 12))
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .sheet(isPresented: $showComments) {
                CommentsView(
                    commentable: $poll,
                    feedViewModel: FeedViewModel()
                )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
            }
        }
        .padding(.horizontal)
        .alert("Change Vote?", isPresented: $showChangeVoteAlert, presenting: selectedOptionForChange) { option in
            Button("Cancel", role: .cancel) { }
            Button("Change Vote") {
                Task {
                    await pollViewModel.voteForOption(option.id, in: poll)
                }
            }
        } message: { option in
            Text("Are you sure you want to change your vote to '\(option.text)'?")
        }
        .alert("Poll expired", isPresented: $showExpiredPollAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This poll expired 😢, you can still comment and make sure to vote in future polls!")
        }
    }
    
    // Helper functions
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func timeRemaining(until date: Date) -> String {
        let remaining = date.timeIntervalSince(Date())
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func selectOption(_ option: PollOption) {
        guard !isPreview else { return }
        
        if !poll.isActive {
            showExpiredPollAlert = true
            return
        }
        
        let hasVotedInfo = pollViewModel.hasUserVotedPolls[poll.id]
        let hasVoted = hasVotedInfo?.hasVoted ?? false
        let userVotedOptionId = hasVotedInfo?.optionId
        
        if hasVoted && userVotedOptionId != option.id {
            selectedOptionForChange = option
            showChangeVoteAlert = true
        } else {
            Task {
                await pollViewModel.voteForOption(option.id, in: poll)
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct PollOptionView: View {
    let option: PollOption
    let isSelected: Bool
    let totalVotes: Int
    let hasVoted: Bool
    let isPreview: Bool
    let isActive: Bool
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background percentage bar
                    if hasVoted && !isPreview {
                        Rectangle()
                            .fill(Color("Colors/AccentColor").opacity(0.4))
                            .frame(width: geometry.size.width * CGFloat(calculatePercentage()) / 100)
                    }
                    
                    // Content
                    HStack {
                        Text(option.text.isEmpty ? "Option" : option.text)
                            .foregroundColor(.primary)
                            .font(.custom("MuseoSansRounded-500", size: 16))
                        
                        Spacer()
                        
                        if hasVoted && !isPreview {
                            Text("\(calculatePercentage())%")
                                .foregroundColor(.secondary)
                                .font(.custom("MuseoSansRounded-500", size: 16))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)  // Fixed height for consistency
            .background(isSelected ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color("Colors/AccentColor") : Color.clear, lineWidth: 2)
            )
        }
        .disabled(isPreview)
        .padding(.horizontal)
    }
    
    private func calculatePercentage() -> Int {
        guard totalVotes > 0 else { return 0 }
        return Int((Double(option.voteCount) / Double(totalVotes)) * 100)
    }
}
