//
//  CustomScrollView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/28/24.
//

import SwiftUI

struct CustomHorizontalScrollView<Content: View>: View {
    let content: Content
    @Binding var currentIndex: Int
    let itemCount: Int
    let itemWidth: CGFloat
    @GestureState private var translation: CGFloat = 0
    @State private var offset: CGFloat = 0
    var onDismiss: (() -> Void)?
    let initialIndex: Int

    init(@ViewBuilder content: () -> Content, currentIndex: Binding<Int>, itemCount: Int, itemWidth: CGFloat, initialIndex: Int, onDismiss: (() -> Void)? = nil) {
        self.content = content()
        self._currentIndex = currentIndex
        self.itemCount = itemCount
        self.itemWidth = itemWidth
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width * CGFloat(itemCount), alignment: .leading)
                .offset(x: -CGFloat(currentIndex) * itemWidth + clampedOffset)
                .gesture(
                    DragGesture()
                        .updating($translation) { value, state, _ in
                            if currentIndex < itemCount - 1 || value.translation.width > 0 {
                                state = value.translation.width
                            }
                        }
                        .onChanged { value in
                            if currentIndex < itemCount - 1 || value.translation.width > 0 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let dragThreshold: CGFloat = itemWidth / 2
                            let draggedDistance = value.predictedEndTranslation.width

                            if currentIndex == 0 && draggedDistance > 50 && abs(draggedDistance) > abs(value.translation.height) {
                                offset = geometry.size.width
                                onDismiss?()
                            } else if currentIndex < itemCount - 1 || draggedDistance > 0 {
                                if draggedDistance > dragThreshold {
                                    currentIndex = max(0, currentIndex - 1)
                                } else if draggedDistance < -dragThreshold && currentIndex < itemCount - 1 {
                                    currentIndex = min(itemCount - 1, currentIndex + 1)
                                }
                            }
                            offset = 0
                        }
                )
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }

    private var clampedOffset: CGFloat {
        if currentIndex == itemCount - 1 {
            return min(0, offset + translation)
        } else {
            return offset + translation
        }
    }
}
