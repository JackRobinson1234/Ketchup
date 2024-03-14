//
//  ImageEditView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 3/13/24.
//

import SwiftUI

struct ImageEditView: View {
    var image: UIImage?
    @State private var readyToPost = false

    var body: some View {
        // Display the image and add your edit/post functionality here
        ZStack {
            if let image = image {
                VStack{
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    Spacer()
                }
            } else {
                Text("No image found")
            }
            
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
    }
}

// This struct provides a preview for the SwiftUI canvas and is only needed for development purposes.
struct ImageEditView_Previews: PreviewProvider {
    static var previews: some View {
        // You can provide a dummy UIImage for preview purposes
        ImageEditView(image: UIImage(systemName: "photo"))
    }
}
