//
//  UploadPostView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI

struct RestaurantUploadPostView: View {
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var tabIndex: Int
    @Binding var cover: Bool
    
    private let restaurant: Restaurant?
    private let movie: Movie
    init(movie: Movie, viewModel: UploadPostViewModel, tabIndex: Binding<Int>, restaurant: Restaurant?,cover: Binding<Bool> ) {
        self.restaurant = restaurant
        self.movie = movie
        self.viewModel = viewModel
        self._tabIndex = tabIndex
        self._cover = cover
    }
    var body: some View {
        VStack {
           
            HStack() {
                if let restaurant{
                    SelectedRestaurantView(restaurant: restaurant)}
                Spacer()
                
                if let uiImage = MediaHelpers.generateThumbnail(path: movie.url.absoluteString) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 125)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
           
            TextField("Enter your caption...", text: $viewModel.caption, axis: .vertical)
                .font(.subheadline)
                .padding(.top, 60)
            
            Divider()
            
            Spacer()
            
            Button {
                Task {
                    try await viewModel.uploadRestaurantPost()
                    if viewModel.uploadSuccess{
                        
                    }
                    else if viewModel.uploadFailure{
                        
                    }
                    viewModel.reset()
                    cover = false
                    tabIndex = 0
                    
                    
                    
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

/*#Preview {
    UploadPostView(movie: Movie(url: URL(string: "")!),
                   viewModel: UploadPostViewModel(service: UploadPostService(restaurantId: restaurants.id[)),
                   tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
} */
