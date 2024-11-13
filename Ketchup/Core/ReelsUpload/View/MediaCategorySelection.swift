//
//  MediaCategorySelection.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/23/24.
//

import SwiftUI
import AVFoundation

struct MediaCategorySelectionView: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    @State private var currentIndex = 0

    var body: some View {
        VStack {
            if currentIndex < uploadViewModel.mixedMediaItems.count {
                let mediaItem = uploadViewModel.mixedMediaItems[currentIndex]
                MediaCategorySelectionItemView(mediaItem: mediaItem) {
                    currentIndex += 1
                }
            } else {
                // Optionally show a loading indicator or message
                Text("Preparing your upload...")
                    .onAppear {
                        uploadViewModel.navigateToMediaCategorySelection = false
                        uploadViewModel.navigateToUpload = true
                    }
            }
        }
        .navigationBarTitle("Add Tags", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            // Handle back action
            uploadViewModel.navigateToMediaCategorySelection = false
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
    }
}

struct MediaCategorySelectionItemView: View {
    @ObservedObject var mediaItem: MixedMediaItemHolder
    var onDone: () -> Void
    @State private var showCategoryOptions = false
    @State private var showDescriptionField = false

    var body: some View {
        VStack {
            // Display the media item
            if mediaItem.type == .photo, let image = mediaItem.localMedia as? UIImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if mediaItem.type == .video, let url = mediaItem.localMedia as? URL {
                VideoPlayer(player: AVPlayer(url: url), videoGravity: .resizeAspectFill)
                    .frame(height: 300)
            }

            // Optional Tagging
            if mediaItem.descriptionCategory == nil {
                // Add Tag Button
                Button(action: {
                    showCategoryOptions = true
                }) {
                    Text("Add Tag")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.cornerRadius(8))
                        .foregroundColor(.white)
                }
                .padding()
            } else {
                // Display Selected Category and Description
                Text("Category: \(mediaItem.descriptionCategory?.rawValue.capitalized ?? "")")
                    .font(.headline)
                    .padding()

                if let description = mediaItem.description, !description.isEmpty {
                    Text("Description: \(description)")
                        .padding()
                } else {
                    // Optionally add a description
                    if mediaItem.descriptionCategory == .food {
                        TextField("Describe the food", text: Binding(
                            get: { mediaItem.description ?? "" },
                            set: { mediaItem.description = $0 }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    }
                }
            }

            // Next Button
            Button(action: {
                onDone()
            }) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.cornerRadius(8))
                    .foregroundColor(.white)
            }
            .padding()
        }
        .padding()
        // Category Selection Sheet
        .actionSheet(isPresented: $showCategoryOptions) {
            ActionSheet(
                title: Text("Select Category"),
                buttons: [
                    .default(Text("Food")) {
                        mediaItem.descriptionCategory = .food
                        showDescriptionField = true
                    },
                    .default(Text("Menu")) {
                        mediaItem.descriptionCategory = .menu
                        showDescriptionField = false
                    },
                    .default(Text("Atmosphere")) {
                        mediaItem.descriptionCategory = .atmosphere
                        showDescriptionField = false
                    },
                    .default(Text("Other")) {
                        mediaItem.descriptionCategory = .other
                        showDescriptionField = false
                    },
                    .cancel()
                ]
            )
        }
    }
}
