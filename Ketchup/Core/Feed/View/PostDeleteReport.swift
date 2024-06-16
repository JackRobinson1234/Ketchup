//
//  ReportingOptionsView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/11/24.
//

import SwiftUI
import FirebaseAuth


struct PostOptionsSheet: View {
    let post: Post
    @ObservedObject var viewModel: FeedViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State var showReportDetails = false
    @State var optionsSheetDismissed: Bool = false
    var body: some View {
        VStack(spacing: 20) {
            if post.user.id == Auth.auth().currentUser?.uid {
                Button {
                    showingDeleteAlert = true
                } label: {
                    Text("Delete Post")
                        .font(.subheadline)
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
            } else {
                Button {
                    showReportDetails = true
                } label: {
                    Text("Report Post")
                        .font(.subheadline)
                        .foregroundColor(.primary)
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
        
    }
}



