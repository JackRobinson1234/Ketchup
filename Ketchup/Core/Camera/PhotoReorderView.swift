//
//  PhotoReorderView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/8/24.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
struct PhotoReorderView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var draggedItem: UIImage?
    @State private var draggedIndex: Int?
    @State private var dropIndex: Int?
    @State private var selectedImage: UIImage?
    @State private var isExpanded: Bool = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Done")
                        .foregroundColor(.blue)
                        .padding()
                }
                Spacer()
            }

            Text("Drag photos to reorder")
                .font(.custom("MuseoSansRounded-300", size: 16))
                .foregroundColor(.gray)
                .padding(.bottom, 5)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cameraViewModel.images.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: cameraViewModel.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width / 2 - 20, height: (UIScreen.main.bounds.width / 2 - 20) * 6/5)
                                .cornerRadius(10)
                                .clipped()
                                .shadow(radius: 5)
                                .onTapGesture {
                                    selectedImage = cameraViewModel.images[index]
                                    isExpanded = true
                                }
                                .onDrag {
                                    self.draggedItem = cameraViewModel.images[index]
                                    self.draggedIndex = index
                                    return NSItemProvider(object: String(index) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: cameraViewModel.images[index], listData: $cameraViewModel.images, current: index, draggedIndex: $draggedIndex, dropIndex: $dropIndex))

                            Button(action: {
                                cameraViewModel.images.remove(at: index)
                                if cameraViewModel.images.isEmpty {
                                    cameraViewModel.isPhotoTaken = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .padding(5)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onChange(of: dropIndex) { _ in
            if let draggedIndex = draggedIndex, let dropIndex = dropIndex {
                reorderImages(from: draggedIndex, to: dropIndex)
            }
        }
        .onChange(of: draggedIndex) { _ in
            if draggedIndex == nil {
                dropIndex = nil
            }
        }
        .sheet(item: $selectedImage) { image in
            ExpandedImageView(image: image, isPresented: $isExpanded)
        }
    }

    private func reorderImages(from source: Int, to destination: Int) {
        if source != destination {
            var images = cameraViewModel.images
            let item = images.remove(at: source)
            images.insert(item, at: destination)
            cameraViewModel.images = images
            self.draggedIndex = destination
        }
    }
}

extension UIImage: Identifiable {
    public var id: String {
        UUID().uuidString
    }
}

struct ExpandedImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var imageLoadError: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if isLoading {
                FastCrossfadeFoodImageView()
                    .scaleEffect(1.5)
            }
            
            if !imageLoadError {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
            } else {
                Text("Failed to load image")
                    .foregroundColor(.white)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            if image.size.width == 0 || image.size.height == 0 {
                imageLoadError = true
            }
        }
    }
}

struct DragRelocateDelegate: DropDelegate {
    let item: UIImage
    @Binding var listData: [UIImage]
    let current: Int
    @Binding var draggedIndex: Int?
    @Binding var dropIndex: Int?

    func dropEntered(info: DropInfo) {
        guard let draggedIndex = draggedIndex else { return }
        if current != draggedIndex {
            withAnimation {
                moveItem(from: draggedIndex, to: current)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedIndex = draggedIndex, let dropIndex = dropIndex else { return false }
        withAnimation {
            moveItem(from: draggedIndex, to: dropIndex)
        }
        self.draggedIndex = nil
        self.dropIndex = nil
        return true
    }

    private func moveItem(from source: Int, to destination: Int) {
        if source != destination {
            var updatedList = listData
            let item = updatedList.remove(at: source)
            updatedList.insert(item, at: destination)
            listData = updatedList
            self.draggedIndex = destination
        }
    }
}
