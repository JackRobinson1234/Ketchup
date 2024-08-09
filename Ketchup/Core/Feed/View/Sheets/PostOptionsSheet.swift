//
//  ReportingOptionsView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import SwiftUI
import FirebaseAuth


struct PostOptionsSheet: View {
    @Binding var post: Post
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    @State var showingEditPost: Bool = false
    @State private var showingRepostSheet = false
    var body: some View {
        VStack(spacing: 20) {
            if post.user.id == Auth.auth().currentUser?.uid {
                VStack(spacing: 15){
                    Button {
                        showingEditPost = true
                    } label : {
                        Text("Edit Post Details")
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(.black)
                    }
                    Divider()
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete Post")
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundStyle(Color("Colors/AccentColor"))
                    }
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(
                            title: Text("Delete Post"),
                            message: Text("Are you sure you want to delete this post?"),
                            primaryButton: .destructive(Text("Delete")) {
                                Task {
                                    await viewModel.deletePost(post: post)
                                    optionsSheetDismissed = true
                                    dismiss()
                                }
                            },
                            secondaryButton: .cancel(Text("Cancel"))
                        )
                    }
                }
            } else {
                Button {
                    showingRepostSheet.toggle()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.2.squarepath")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                            .rotationEffect(.degrees(90))
                        Text("Repost")
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 10)
                    .disabled(post.user.id == AuthService.shared.userSession?.id)
                    
                }
                Divider()
                Button {
                    showReportDetails = true
                } label: {
                    Text("Report Post")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .foregroundColor(.black)
                }
            }
        }
        .onChange(of: optionsSheetDismissed) {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .onAppear {
            if optionsSheetDismissed {
                dismiss()
            }
        }
        .padding()
        .sheet(isPresented: $showReportDetails) {
            ReportingView(contentId: post.id, objectType: "post", dismissView: $optionsSheetDismissed )
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                .onDisappear{
                    dismiss()
                }
                
        }
        .sheet(isPresented: $showingRepostSheet) {
                    RepostView(viewModel: viewModel, post: post)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.35)])
                        .onDisappear{
                            dismiss()
                        }
                }
        .fullScreenCover(isPresented: $showingEditPost){
            NavigationStack{
                ReelsEditView(post: $post, feedViewModel: viewModel)
            }
            .onDisappear{
                dismiss()
            }
        }
        
    }
}
