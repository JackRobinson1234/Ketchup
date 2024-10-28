//
//  TaggingSheetView.swift
//  Ketchup
//
//  Created by Jack Robinson on 10/25/24.
//

import SwiftUI
import AVFoundation

struct TaggingSheetView: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    @State private var currentIndex = 0
    @Environment(\.presentationMode) var presentationMode
    @State private var videoPlayers: [Int: VideoPlayerTest] = [:]
    @State private var isPlaying: Bool = false
    @State private var volume: Float = 0.5
    
    private let expandedWidth: CGFloat = UIScreen.main.bounds.width * 5/6
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with "Done" button
                HStack {
                    Spacer()
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color("Colors/AccentColor"))
                    .padding()
                }
                
                // Media Preview Section
                VStack(spacing: 8) {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<uploadViewModel.mixedMediaItems.count, id: \.self) { index in
                            let item = uploadViewModel.mixedMediaItems[index]
                            Group {
                                if item.type == .photo {
                                    if let image = item.localMedia as? UIImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Color.gray // Placeholder
                                    }
                                } else if item.type == .video {
                                    VideoPlayerTest(videoURL: item.localMedia as? URL,
                                                    isVideoExpanded: .constant(true),
                                                    isPlaying: $isPlaying,
                                                    volume: $volume) { player in
                                        videoPlayers[index] = player
                                    }
                                }
                            }
                            .frame(width: expandedWidth, height: expandedWidth * 6/5)
                            .cornerRadius(10)
                            .clipped()
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .frame(width: expandedWidth, height: expandedWidth * 6/5)
                    
                    if uploadViewModel.mixedMediaItems[currentIndex].type == .video {
                        VideoControlButtons(
                            isPlaying: $isPlaying,
                            volume: $volume,
                            onPlayPause: {
                                videoPlayers[currentIndex]?.togglePlayPause()
                            },
                            onVolumeToggle: {
                                videoPlayers[currentIndex]?.toggleVolume()
                            }
                        )
                        .frame(width: expandedWidth)
                    }
                }
                
                // Content below media preview
                VStack(spacing: 0) {
                    Text("What's in this \(uploadViewModel.mixedMediaItems[currentIndex].type == .photo ? "photo" : "video")?")
                        .font(.custom("MuseoSansRounded-700", size: 20))
                        .foregroundColor(.black)
                        .padding()
                    
                    CategoryButtonsView(
                        mediaItem: uploadViewModel.mixedMediaItems[currentIndex],
                        onCategorySelected: { category in
                            uploadViewModel.mixedMediaItems[currentIndex].descriptionCategory = category
                            if category == nil {
                                uploadViewModel.mixedMediaItems[currentIndex].description = nil
                            }
                            uploadViewModel.objectWillChange.send()
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    
                    if uploadViewModel.mixedMediaItems[currentIndex].descriptionCategory != nil {
                        Divider()
                        
                        DescriptionFieldView(
                            text: Binding(
                                get: { uploadViewModel.mixedMediaItems[currentIndex].description ?? "" },
                                set: { newValue in
                                    uploadViewModel.mixedMediaItems[currentIndex].description = newValue
                                    uploadViewModel.objectWillChange.send()
                                }
                            )
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .transition(.opacity.animation(.easeInOut))
                        
                        Divider()
                    }
                }
            }
        }
    }
}

// Modified CategoryButtonsView to ensure descriptionCategory is optional
struct CategoryButtonsView: View {
    let mediaItem: MixedMediaItemHolder
    let onCategorySelected: (DescriptionCategory?) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionButton(title: "Food", icon: "fork.knife", category: .food)
                actionButton(title: "Menu", icon: "list.bullet", category: .menu)
            }
            HStack(spacing: 12) {
                actionButton(title: "Atmosphere", icon: "leaf", category: .atmosphere)
                actionButton(title: "Other", icon: "ellipsis", category: .other)
            }
        }
    }
    
    private func actionButton(title: String, icon: String, category: DescriptionCategory) -> some View {
        let isSelected = mediaItem.descriptionCategory == category
        return Button(action: {
            if isSelected {
                // Deselect
                onCategorySelected(nil)
            } else {
                // Select
                onCategorySelected(category)
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.custom("MuseoSansRounded-500", size: 14))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .foregroundColor(isSelected ? .white : .primary)
        .background(
            Capsule()
                .fill(isSelected ? Color("Colors/AccentColor") : Color.clear)
        )
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}


// Separate view for description field
struct DescriptionFieldView: View {
    @Binding var text: String
    @State private var placeholderVisible = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: Binding(
                    get: { text },
                    set: { newValue in
                        if newValue.count <= 100 {
                            text = newValue
                        } else {
                            text = String(newValue.prefix(100))
                        }
                        placeholderVisible = text.isEmpty
                    }
                ))
                .frame(minHeight: 100, maxHeight: 150)
                .padding(4)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                
                if placeholderVisible {
                    Text("Add a description...")
                        .foregroundColor(Color.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            
            Text("\(text.count)/100")
                .font(.caption)
                .foregroundColor(text.count >= 100 ? .red : .gray)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            placeholderVisible = text.isEmpty
        }
    }
}
