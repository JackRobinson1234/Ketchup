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
        VStack(alignment: .leading, spacing: 16) {
            HStack{
                Spacer()
                if let imageUrl = viewModel.poll.imageUrl {
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                Spacer()
            }
            Text(viewModel.poll.question)
                .foregroundStyle(.black)
                .padding(.horizontal)
                .font(.custom("MuseoSansRounded-700", size: 20))
            
            
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
        }
        .padding(.vertical)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showComments) {
            PollCommentsView(pollId: viewModel.poll.id ?? "", commentCount: viewModel.poll.commentCount)
        }
    }
    
    private var timeRemaining: String {
        let remaining = viewModel.poll.expiresAt.timeIntervalSince(Date())
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func selectOption(_ option: Poll.PollOption) {
        guard selectedOption == nil else { return }  // Prevent changing vote
        selectedOption = option.id
        Task {
            await viewModel.voteForOption(option.id)
        }
    }
}

struct PollOptionView: View {
    let option: Poll.PollOption
    let isSelected: Bool
    let totalVotes: Int
    let hasVoted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text)
                    .foregroundColor(isSelected ? .white : .primary)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                
                Spacer()
                
                if hasVoted {
                    Text("\(calculatePercentage())% (\(option.voteCount))")
                        .foregroundColor(isSelected ? .white : .secondary)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
            }
            .padding()
            .background(isSelected ? Color("Colors/AccentColor"): Color.gray.opacity(0.1))
            .cornerRadius(10)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(Color("Colors/AccentColor"), lineWidth: isSelected ? 2 : 0)
//            )
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
