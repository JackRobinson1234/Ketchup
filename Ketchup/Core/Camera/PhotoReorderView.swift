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

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
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

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(cameraViewModel.images.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: cameraViewModel.images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 104, height: 225)
                                .cornerRadius(10)
                                .clipped()
                                .shadow(radius: 5)
                                //.offset(y: draggedIndex == index ? -20 : 0)
                                .onDrag {
                                    self.draggedItem = cameraViewModel.images[index]
                                    self.draggedIndex = index
                                    return NSItemProvider(object: String(index) as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: DragRelocateDelegate(item: cameraViewModel.images[index], listData: $cameraViewModel.images, current: index, draggedIndex: $draggedIndex, dropIndex: $dropIndex))
                                .onHover { hovering in
                                    if hovering {
                                        self.dropIndex = index
                                    } else {
                                        if self.dropIndex == index {
                                            self.dropIndex = nil
                                        }
                                    }
                                }

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
