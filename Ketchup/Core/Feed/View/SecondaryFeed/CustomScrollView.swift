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
    @State private var draggingOffset: CGFloat = 0
    var onDismiss: (() -> Void)?
    let initialIndex: Int
    
    // New state to track if we're in dismiss gesture
    @State private var isDismissing: Bool = false

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
                .offset(x: -CGFloat(currentIndex) * itemWidth + offset + draggingOffset)
                .animation(.interactiveSpring(), value: offset)
                .gesture(
                    DragGesture()
                        .updating($translation) { value, state, _ in
                            if !isDismissing {
                                state = value.translation.width
                            }
                        }
                        .onChanged { value in
                            if !isDismissing {
                                draggingOffset = value.translation.width
                                
                                // Check for dismiss gesture
                                if currentIndex == 0 && value.translation.width > 50 && abs(value.translation.width) > abs(value.translation.height) {
                                    isDismissing = true
                                    onDismiss?()
                                }
                            }
                        }
                        .onEnded { value in
                            if !isDismissing {
                                let dragThreshold: CGFloat = itemWidth / 3
                                let draggedDistance = value.predictedEndTranslation.width

                                withAnimation(.interactiveSpring()) {
                                    if draggedDistance > dragThreshold && currentIndex > 0 {
                                        currentIndex -= 1
                                    } else if draggedDistance < -dragThreshold && currentIndex < itemCount - 1 {
                                        currentIndex += 1
                                    }
                                    offset = 0
                                    draggingOffset = 0
                                }
                            }
                        }
                )
        }
        .onAppear {
            currentIndex = initialIndex
        }
    }
}
