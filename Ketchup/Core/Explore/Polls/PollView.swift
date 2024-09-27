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
    @StateObject private var viewModel: PollViewModel
    @State private var selectedOption: String?
    @State private var showComments = false
    
    init(poll: Poll) {
        _viewModel = StateObject(wrappedValue: PollViewModel(poll: poll))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                if let imageUrl = viewModel.poll.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Image("Skip")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                            Spacer()
                        }
                        Spacer()
                    }
                }
                
                // Shadow gradient overlay
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.3), Color.black.opacity(0)]),
                               startPoint: .bottom,
                               endPoint: .top)
                    .frame(height: 200)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Title and Date
                    HStack {
                        Text("Daily Poll")
                            .font(.custom("MuseoSansRounded-700", size: 18))
                        Text("• \(formattedDate)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                    
                    // Question text
                    Text(viewModel.poll.question)
                        .foregroundColor(.white)
                        .font(.custom("MuseoSansRounded-700", size: 20))
                }
                .padding(.horizontal)
                .padding(.bottom)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.poll.options) { option in
                    PollOptionView(
                        option: option,
                        isSelected: selectedOption == option.id,
                        totalVotes: viewModel.poll.totalVotes,
                        hasVoted: selectedOption != nil
                    ) {
                        selectOption(option)
                    }
                }
                
                HStack {
                    if let selectedOption = selectedOption {
                        Text("Total votes: \(viewModel.poll.totalVotes)")
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
                        InteractionButtonView(icon: "ellipsis.bubble", count: viewModel.poll.commentCount)
                    }
                }
                .padding(.horizontal)
                
                Text("Poll expires in: \(timeRemaining)")
                    .font(.custom("MuseoSansRounded-300", size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom)
            }
            .padding(.top)
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            PollCommentsView(pollId: viewModel.poll.id ?? "", commentCount: viewModel.poll.commentCount)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: viewModel.poll.createdAt)
    }
    
    private var timeRemaining: String {
        let remaining = viewModel.poll.expiresAt.timeIntervalSince(Date())
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func selectOption(_ option: PollOption) {
        guard selectedOption == nil else { return }  // Prevent changing vote
        selectedOption = option.id
        Task {
            await viewModel.voteForOption(option.id)
        }
    }
}
struct PollOptionView: View {
    let option: PollOption
    let isSelected: Bool
    let totalVotes: Int
    let hasVoted: Bool
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text)
                    .foregroundColor(.primary)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                
                Spacer()
                
                if hasVoted {
                    Text("\(calculatePercentage())% (\(option.voteCount))")
                        .foregroundColor(.secondary)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color("Colors/AccentColor") : Color.clear, lineWidth: 2)
            )
        }
        .disabled(hasVoted)
        .padding(.horizontal)
    }
    
    private func calculatePercentage() -> Int {
        guard totalVotes > 0 else { return 0 }
        return Int((Double(option.voteCount) / Double(totalVotes)) * 100)
    }
}

struct PollCommentsView: View {
    let pollId: String
    let commentCount: Int
    
    var body: some View {
        // Implement the comments view here
        Text("Comments for poll: \(pollId)")
        
        Text("Total comments: \(commentCount)")
    }
}

struct PollView_Previews: PreviewProvider {
    static var previews: some View {
        PollView(poll: Poll.createNewPoll(
            question: "What's your favorite color?",
            options: ["Red", "Blue", "Green", "Yellow"],
            imageUrl: "https://example.com/colorful-image.jpg"
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
