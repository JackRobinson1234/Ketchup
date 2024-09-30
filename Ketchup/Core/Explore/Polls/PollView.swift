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
    @State private var showComments = false
    var isPreview: Bool = false
    var selectedImage: UIImage?

    init(poll: Poll? = nil, selectedImage: UIImage? = nil, isPreview: Bool = false) {
        _viewModel = StateObject(wrappedValue: PollViewModel(poll: poll))
        self.isPreview = isPreview
        self.selectedImage = selectedImage
    }

    var body: some View {
        VStack {
            if var poll = viewModel.poll {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } else if let imageUrl = poll.imageUrl, !imageUrl.isEmpty {
                            KFImage(URL(string: imageUrl))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } else {
                            // Placeholder
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Image("Skip")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .opacity(0.6)
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
                    .frame(height: 200)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(poll.options) { option in
                            PollOptionView(
                                option: option,
                                isSelected: viewModel.userVotedOptionId == option.id,
                                totalVotes: poll.totalVotes,
                                hasVoted: viewModel.hasUserVoted,
                                isPreview: isPreview,
                                action: {
                                    selectOption(option)
                                }
                            )
                        }

                        if !isPreview {
                            // Interaction buttons and expiration info
                            HStack {
                                if viewModel.hasUserVoted {
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

                            Text("Poll expires in: \(timeRemaining(until: poll.expiresAt))")
                                .font(.custom("MuseoSansRounded-300", size: 12))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .sheet(isPresented: $showComments) {
                    CommentsView(
                        commentable: Binding(get: { poll}, set: { poll = $0 }), feedViewModel: FeedViewModel())
                               }
            } else {
                Text("Loading poll...")
            }
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
    let isPreview: Bool

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.text.isEmpty ? "Option" : option.text)
                    .foregroundColor(.primary)
                    .font(.custom("MuseoSansRounded-500", size: 16))

                Spacer()

                if hasVoted && !isPreview {
                    Text("\(calculatePercentage())% (\(option.voteCount))")
                        .foregroundColor(.secondary)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                }
            }
            .padding()
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
