//
//  Social Page.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/16/24.
//

import SwiftUI

import SwiftUI
import Firebase
import CoreLocation
import Contacts
import Kingfisher

//struct SocialPage: View {
//    @StateObject private var viewModel = SocialPageViewModel()
//    @State private var showContacts = false
//    @State private var shouldShowExistingUsersOnContacts = false
//    @State private var showPollUploadView = false
//    @StateObject private var pollViewModel = PollViewModel()
//    @State private var currentTabHeight: CGFloat = 650
//    @State private var selectedPollIndex: Int = 0
//    @StateObject var feedViewModel = FeedViewModel()
//    @State var selectedPost: Post? = nil
//
//    var body: some View {
//        NavigationView {
//            ScrollView{
//                VStack(spacing: 25) {
//                    inviteContactsButton
//                    dailyPollContent
//                    friendsContent
//                }
//            }
//            .navigationBarHidden(true)
//            .onAppear {
//                viewModel.checkContactPermission()
//                pollViewModel.fetchPolls()
//            }
//            .sheet(isPresented: $showContacts) {
//                ContactsView(shouldFetchExistingUsers: shouldShowExistingUsersOnContacts)
//            }
//            .sheet(isPresented: $showPollUploadView) {
//                PollUploadView()
//            }
//        }
//    }
//
//    private var inviteContactsButton: some View {
//        VStack(spacing: 0) {
//            Button {
//                shouldShowExistingUsersOnContacts = false
//                showContacts = true
//            } label: {
//                VStack {
//                    Divider()
//                    HStack {
//                        Image(systemName: "envelope")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 30)
//                            .foregroundColor(.black)
//                        VStack(alignment: .leading) {
//                            Text("Invite your friends to Ketchup!")
//                                .font(.custom("MuseoSansRounded-700", size: 16))
//                            VStack(alignment: .leading, spacing: 3) {
//                                GeometryReader { geometry in
//                                    ZStack(alignment: .leading) {
//                                        Rectangle()
//                                            .fill(Color.gray.opacity(0.3))
//                                            .frame(height: 4)
//                                            .cornerRadius(4)
//                                        Rectangle()
//                                            .fill(Color("Colors/AccentColor"))
//                                            .frame(width: min(CGFloat(min(AuthService.shared.userSession?.totalReferrals ?? 0, 10)) / 10.0 * geometry.size.width, geometry.size.width), height: 4)
//                                            .cornerRadius(4)
//                                    }
//                                }
//                                .frame(height: 8)
//                                HStack(spacing: 1) {
//                                    Text("You have \(min(AuthService.shared.userSession?.totalReferrals ?? 0, 10))/10 referrals to earn the launch badge")
//                                        .font(.custom("MuseoSansRounded-500", size: 10))
//                                        .foregroundColor(.gray)
//                                    if let totalReferrals = AuthService.shared.userSession?.totalReferrals, totalReferrals >= 10 {
//                                        Image("LAUNCH")
//                                    } else {
//                                        Image("LAUNCHBLACK")
//                                            .resizable()
//                                            .scaledToFit()
//                                            .frame(height: 12)
//                                            .opacity(0.5)
//                                    }
//                                }
//                            }
//                        }
//                        .foregroundColor(.black)
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .foregroundColor(.gray)
//                    }
//                    .padding()
//                    Divider()
//                }
//            }
//        }
//    }
//
//    private var dailyPollContent: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                VStack(alignment: .leading) {
//                    HStack {
//                        Text("Daily Poll")
//                            .font(.custom("MuseoSansRounded-700", size: 25))
//                            .foregroundColor(.black)
//
//                        if !hasUserVotedToday() {
//                            Circle()
//                                .fill(Color.red)
//                                .frame(width: 8, height: 8)
//                        }
//                    }
//                    .padding(.horizontal)
//
//                    HStack(spacing: 2) {
//                        Text("🔥\(AuthService.shared.userSession?.pollStreak ?? 0) day streak")
//                            .font(.custom("MuseoSansRounded-500", size: 14))
//                            .foregroundColor(.black)
//                    }
//                    .padding(.horizontal)
//                }
//                Spacer()
//                if let userId = AuthService.shared.userSession?.id,
//                   ["uydfmAuFmCWOvSuLaGYuSKQO8Qn2", "cQlKGlOWTOSeZcsqObd4Iuy6jr93", "4lwAIMZ8zqgoIljiNQmqANMpjrk2"].contains(userId) {
//                    Button {
//                        showPollUploadView = true
//                    } label: {
//                        Text("Poll Manager")
//                            .font(.custom("MuseoSansRounded-300", size: 12))
//                            .modifier(StandardButtonModifier(width: 80))
//                            .padding(.trailing)
//                    }
//                }
//            }
//
//            if !pollViewModel.polls.isEmpty {
//                VStack(spacing: 10) {
//                    TabView(selection: $selectedPollIndex) {
//                        ForEach(pollViewModel.polls.indices, id: \.self) { index in
//                            PollView(poll: $pollViewModel.polls[index], pollViewModel: pollViewModel, feedViewModel: feedViewModel)
//                                .background(
//                                    GeometryReader { geometry in
//                                        Color.clear
//                                            .onAppear {
//                                                if index == selectedPollIndex {
//                                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                                        currentTabHeight = geometry.size.height + 15
//                                                    }
//                                                }
//                                            }
//                                            .onChange(of: selectedPollIndex) { _ in
//                                                if index == selectedPollIndex {
//                                                    withAnimation(.easeInOut(duration: 0.3)) {
//                                                        currentTabHeight = geometry.size.height + 15
//                                                    }
//                                                }
//                                            }
//                                    }
//                                )
//                                .tag(index)
//                        }
//                    }
//                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//                    .frame(height: currentTabHeight)
//                    Text("Swipe to see previous polls")
//                        .font(.custom("MuseoSansRounded-300", size: 10))
//                        .foregroundColor(.gray.opacity(0.8))
//                        .padding(.bottom, 5)
//                }
//            }
//        }
//    }
//
//    private var friendsContent: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text("Friends on Ketchup")
//                    .font(.custom("MuseoSansRounded-700", size: 25))
//                    .foregroundColor(.black)
//                Spacer()
//                Button("See All") {
//                    shouldShowExistingUsersOnContacts = true
//                    showContacts = true
//                }
//                .font(.custom("MuseoSansRounded-300", size: 12))
//                .foregroundColor(.gray)
//            }
//            .padding(.horizontal)
//            if let user = AuthService.shared.userSession, user.contactsSynced, viewModel.isContactPermissionGranted {
//                if !viewModel.topContacts.isEmpty {
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        LazyHStack(spacing: 16) {
//                            ForEach(viewModel.topContacts) { contact in
//                                SocialContactRow(viewModel: viewModel, contact: contact)
//                                    .onAppear {
//                                        if contact == viewModel.topContacts.last {
//                                            viewModel.loadMoreContacts()
//                                        }
//                                    }
//                            }
//                            if viewModel.isLoadingMore {
//                                FastCrossfadeFoodImageView()
//                                    .frame(width: 50, height: 50)
//                            }
//                            if viewModel.hasMoreContacts {
//                                Color.clear
//                                    .frame(width: 1, height: 1)
//                                    .onAppear { viewModel.loadMoreContacts() }
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                } else {
//                    Button {
//                        shouldShowExistingUsersOnContacts = false
//                        showContacts = true
//                    } label: {
//                        Text("We couldn't find any friends in your contacts, invite them!")
//                            .foregroundColor(.black)
//                            .font(.custom("MuseoSansRounded-700", size: 14))
//                            .padding(.horizontal)
//                    }
//                }
//            } else {
//                Button {
//                    openSettings()
//                } label: {
//                    HStack {
//                        Spacer()
//                        VStack {
//                            Text("Allow Ketchup to access your contacts to make finding friends easier!")
//                                .foregroundColor(.black)
//                                .font(.custom("MuseoSansRounded-500", size: 14))
//                                .padding(.vertical)
//                            Text("Go to settings")
//                                .foregroundColor(Color("Colors/AccentColor"))
//                                .font(.custom("MuseoSansRounded-700", size: 14))
//                        }
//                        Spacer()
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//
//    private func hasUserVotedToday() -> Bool {
//        guard let lastVotedDate = AuthService.shared.userSession?.lastVotedPoll else {
//            return false // User has never voted
//        }
//
//        let calendar = Calendar.current
//        let losAngelesTimeZone = TimeZone(identifier: "America/Los_Angeles")!
//
//        let lastVotedDateLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: lastVotedDate)!
//        let nowLA = calendar.date(byAdding: .hour, value: losAngelesTimeZone.secondsFromGMT() / 3600, to: Date())!
//
//        let lastVotedDay = calendar.startOfDay(for: lastVotedDateLA)
//        let todayLA = calendar.startOfDay(for: nowLA)
//
//        return calendar.isDate(lastVotedDay, inSameDayAs: todayLA)
//    }
//
//    private func openSettings() {
//        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
//            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
//        }
//    }
//}
