//
//  UploadPostView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct UploadPostView: View {
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var tabIndex: Int
    private let restaurant: Restaurant
    private let movie: Movie
    init(movie: Movie, viewModel: UploadPostViewModel, tabIndex: Binding<Int>, restaurant: Restaurant) {
        self.restaurant = restaurant
        self.movie = movie
        self.viewModel = viewModel
        self._tabIndex = tabIndex
    }
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                TextField("Enter your caption..", text: $viewModel.caption, axis: .vertical)
                    .font(.subheadline)
                
                Spacer()
                
                if let uiImage = MediaHelpers.generateThumbnail(path: movie.url.absoluteString) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            Divider()
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.uploadPost()
                    tabIndex = 0
                    viewModel.reset()
                    dismiss()
                }
            } label: {
                Text(viewModel.isLoading ? "" : "Post")
                    .modifier(StandardButtonModifier())
                    .overlay {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                    }
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        }
    }
}

#Preview {
    UploadPostView(movie: Movie(url: URL(string: "")!),
                   viewModel: UploadPostViewModel(service: UploadPostService()),
                   tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
}
