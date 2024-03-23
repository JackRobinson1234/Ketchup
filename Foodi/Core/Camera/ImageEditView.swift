//
//  ImageEditView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/13/24.
//

import SwiftUI

struct ImageEditView: View {
    @State private var readyToPost = false
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: CameraViewModel
    
    init(selectedTab: Binding<Int>, viewModel: CameraViewModel) {
        self._selectedTab = selectedTab
        self.viewModel = viewModel
    }
    

    var body: some View {
        // Display the image and add your edit/post functionality here
        ZStack {
            Image(uiImage: viewModel.capturedPhoto ?? UIImage(systemName: "photo")!)
                .resizable()
                .scaledToFit()
            
//            switch viewModel.mediaPreview {
//            case .photo(let photo):
//                // For a photo, you would display it similar to before
//                // You'll need to adjust how you obtain a UIImage from your Photo structure
//                if let uiImage = UIImage(contentsOfFile: photo.url.path) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFit()
//                } else {
//                    Text("No image found")
//                }
//                
//            case .movie(let movie):
//                // For a movie, you could display a thumbnail
//                // You'll need to implement logic to extract a thumbnail from the movie's URL
//                if let uiImage = MediaHelpers.generateThumbnail(path: movie.url.absoluteString) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFit()
//                } else {
//                    Text("No video thumbnail found")
//                }
//                
//            default:
//                Text("No media found")
//            }
            
            VStack {
                Spacer()
                Button {
                    readyToPost = true
                } label: {
                    Image(systemName: "checkmark.circle.fill") // Change the system name as per your requirement
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50) // Adjust size as needed
                        .background(Circle().fill(Color.gray)) // Surround the button with a circle
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
            }
        }
//        .navigationDestination(isPresented: $readyToPost) {
//            CreatePostSelection(selectedTab: $selectedTab, viewModel: viewModel)
//        }
    }
}

// This struct provides a preview for the SwiftUI canvas and is only needed for development purposes.
//struct ImageEditView_Previews: PreviewProvider {
//    @State static var selectedTabPreview: Int = 2
//    static var previews: some View {
//        // You can provide a dummy UIImage for preview purposes
//        ImageEditView(image: UIImage(systemName: "photo"), selectedTab: .constant(2))
//    }
//}
