//
//  ImageCropper.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/9/24.
//

import SwiftUI

struct ImageCropper: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var draggedOffset: CGSize = .zero
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(scale)
                        .offset(x: offset.width + draggedOffset.width, y: offset.height + draggedOffset.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale *= delta
                                }
                                .onEnded { _ in
                                    lastScale = 1
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    draggedOffset = value.translation
                                }
                                .onEnded { _ in
                                    offset.width += draggedOffset.width
                                    offset.height += draggedOffset.height
                                    draggedOffset = .zero
                                }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipShape(Circle())
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }

                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Done") {
                        let croppedImage = cropImage(image, scale: scale, offset: offset, size: geometry.size)
                        onCrop(croppedImage)
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
    
    func cropImage(_ inputImage: UIImage, scale: CGFloat, offset: CGSize, size: CGSize) -> UIImage {
        let scaledSize = CGSize(width: size.width / scale, height: size.width / scale)
        let center = CGPoint(x: inputImage.size.width / 2, y: inputImage.size.height / 2)
        let origin = CGPoint(
            x: center.x - scaledSize.width / 2 + offset.width / scale,
            y: center.y - scaledSize.height / 2 + offset.height / scale
        )
        let scaledRect = CGRect(origin: origin, size: scaledSize)
        
        UIGraphicsBeginImageContextWithOptions(size, false, inputImage.scale)
        inputImage.draw(in: CGRect(x: -scaledRect.origin.x, y: -scaledRect.origin.y, width: inputImage.size.width, height: inputImage.size.height))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return croppedImage ?? inputImage
    }
}
