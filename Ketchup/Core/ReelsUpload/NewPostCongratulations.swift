//
//  NewPostUploadView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/26/24.
//

import SwiftUI
import Kingfisher
struct NewPostCongratulations: View {
    @Binding var isShown: Bool
    var debouncer = Debouncer(delay: 10.0)
    @State private var animationTrigger = false
    
    var body: some View {
        ZStack {
            Color.white
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            FallingFoodView()
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                if let post = UploadService.shared.newestPost {
                    VStack(spacing: 4) {
                        Text("Post Uploaded!")
                            .font(.custom("MuseoSansRounded-900", size: 36))
                            .foregroundColor(Color("Colors/AccentColor"))
                            .opacity(animationTrigger ? 1 : 0)
                            .scaleEffect(animationTrigger ? 1 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.2), value: animationTrigger)
                        
                        if let user = AuthService.shared.userSession {
                            HStack(spacing: 2) {
                                Text("🔥\(user.weeklyStreak) week streak")
                                    .font(.custom("MuseoSansRounded-700", size: 24))
                                    .foregroundColor(.black)
                            }
                            .opacity(animationTrigger ? 1 : 0)
                            .scaleEffect(animationTrigger ? 1 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.4), value: animationTrigger)
                            
                            Text("Total posts: \(user.stats.posts)")
                                .font(.custom("MuseoSansRounded-700", size: 16))
                                .foregroundColor(.black)
                                .opacity(animationTrigger ? 1 : 0)
                                .scaleEffect(animationTrigger ? 1 : 0.5)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.6), value: animationTrigger)
                        }
                        
                        WrittenFeedCell(viewModel: FeedViewModel(), post: .constant(post), scrollPosition: .constant(nil), pauseVideo: .constant(false), selectedPost: .constant(nil), checkLikes: false, hideActionButtons: true)
                            .opacity(animationTrigger ? 1 : 0)
                            .scaleEffect(animationTrigger ? 0.7 : 0.3)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.8), value: animationTrigger)
                    }
                    .background(.white)
                    .cornerRadius(14)
                }
                
                Spacer()
                Button {
                    UploadService.shared.newestPost = nil
                    isShown = false
                } label: {
                    Text("Continue")
                        .font(.custom("MuseoSansRounded-700", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Colors/AccentColor"))
                        .cornerRadius(25)
                }
                .opacity(animationTrigger ? 1 : 0)
                .scaleEffect(animationTrigger ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(1), value: animationTrigger)
            }
            .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationTrigger = true
            }
        }
    }
}
