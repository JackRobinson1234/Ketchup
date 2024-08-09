import SwiftUI

struct CommentInputView: View {
    @ObservedObject var viewModel: CommentViewModel
    @FocusState var isInputFocused: Bool
    
    var body: some View {
        VStack {
            if let replyingTo = viewModel.replyingTo {
                HStack {
                    Text("Replying to @\(replyingTo.replyToUser)")
                        .font(.custom("MuseoSansRounded-300", size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.cancelReply()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            
            ZStack(alignment: .trailing) {
                TextField("Add a comment", text: $viewModel.commentText, axis: .vertical)
                    .padding(10)
                    .padding(.leading, 4)
                    .padding(.trailing, 48)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .focused($isInputFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                
                Button {
                    Task {
                        await viewModel.uploadComment()
                        isInputFocused = false
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Color("Colors/AccentColor"))
                }
                .padding(.horizontal)
                .disabled(viewModel.commentText.isEmpty)
            }
            .tint(.black)
        }
    }
}
