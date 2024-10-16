//
//  DailyPollContentView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/16/24.
//

import SwiftUI

struct DailyPollContentView: View {
    @ObservedObject var pollViewModel: PollViewModel
    @ObservedObject var feedViewModel: FeedViewModel
    @Binding var currentTabHeight: CGFloat
    @Binding var selectedPollIndex: Int
    @Binding var showPollUploadView: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Daily Poll")
                            .font(.custom("MuseoSansRounded-700", size: 25))
                            .foregroundColor(.black)
                        
                        if !hasUserVotedToday() {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 2) {
                        Text("🔥\(AuthService.shared.userSession?.pollStreak ?? 0) day streak")
                            .font(.custom("MuseoSansRounded-500", size: 14))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                }
                Spacer()
                if let userId = AuthService.shared.userSession?.id,
                   ["uydfmAuFmCWOvSuLaGYuSKQO8Qn2", "cQlKGlOWTOSeZcsqObd4Iuy6jr93", "4lwAIMZ8zqgoIljiNQmqANMpjrk2"].contains(userId) {
                    Button {
                        showPollUploadView = true
                    } label: {
                        Text("Poll Manager")
                            .font(.custom("MuseoSansRounded-300", size: 12))
                            .modifier(StandardButtonModifier(width: 80))
                            .padding(.trailing)
                    }
                }
            }
            
            if !pollViewModel.polls.isEmpty {
                VStack(spacing: 10) {
                    TabView(selection: $selectedPollIndex) {
                        ForEach(pollViewModel.polls.indices, id: \.self) { index in
                            PollView(
                                poll: $pollViewModel.polls[index],
                                pollViewModel: pollViewModel,
                                feedViewModel: feedViewModel
                            )
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            if index == selectedPollIndex {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentTabHeight = geometry.size.height + 15
                                                }
                                            }
                                        }
                                        .onChange(of: selectedPollIndex) { _ in
                                            if index == selectedPollIndex {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentTabHeight = geometry.size.height + 15
                                                }
                                            }
                                        }
                                }
                            )
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: currentTabHeight)
                    Text("Swipe to see previous polls")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.bottom, 5)
                }
            }
        }
    }
    
    private func hasUserVotedToday() -> Bool {
        guard let lastVotedDate = AuthService.shared.userSession?.lastVotedPoll else {
            return false // User has never voted
        }
        
        let calendar = Calendar.current
        let losAngelesTimeZone = TimeZone(identifier: "America/Los_Angeles")!
        
        let lastVotedDateLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: lastVotedDate)!
        let nowLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: Date())!
        
        let lastVotedDay = calendar.startOfDay(for: lastVotedDateLA)
        let todayLA = calendar.startOfDay(for: nowLA)
        
        return calendar.isDate(lastVotedDay, inSameDayAs: todayLA)
    }
}
