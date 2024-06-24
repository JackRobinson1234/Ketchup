//
//  CommentInputView.swift
//  Foodi
//
//  Created by Jack Robinson on 1/31/24.
//

import Foundation
import SwiftUI

struct CommentInputView: View {
    @ObservedObject var viewModel: CommentViewModel
    @FocusState private var fieldIsActive: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .trailing) {
                TextField("Add a comment", text: $viewModel.commentText, axis: .vertical)
                    .padding(10)
                    .padding(.leading, 4)
                    .padding(.trailing, 48)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .focused($fieldIsActive)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                
                Button {
                    Task {
                        await viewModel.uploadComment()
                        fieldIsActive = false
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color("Colors/AccentColor"))
                }
                .padding(.horizontal)
            }
            .tint(.primary)
            
            if viewModel.charLimitReached {
                Text("Max characters reached")
                    .foregroundColor(.red)
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .padding(.top, 4)
            }
        }
    }
}
