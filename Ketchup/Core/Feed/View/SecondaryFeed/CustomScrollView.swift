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
    @State private var dragStartOffset: CGFloat = 0
    var onDismiss: (() -> Void)?

    init(@ViewBuilder content: () -> Content, currentIndex: Binding<Int>, itemCount: Int, itemWidth: CGFloat, onDismiss: (() -> Void)? = nil) {
        self.content = content()
        self._currentIndex = currentIndex
        self.itemCount = itemCount
        self.itemWidth = itemWidth
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width * CGFloat(itemCount), alignment: .leading)
                .offset(x: -CGFloat(currentIndex) * itemWidth + translation + offset)
                .gesture(
                    DragGesture()
                        .updating($translation) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let predictedEndOffset = -CGFloat(currentIndex) * itemWidth + value.predictedEndTranslation.width
                            let predictedIndex = Int(round(predictedEndOffset / -itemWidth))
                            
                            if currentIndex == 0 && value.translation.width > 50 && abs(value.translation.width) > abs(value.translation.height) {
                                onDismiss?()
                            } else {
                                
                                    currentIndex = max(0, min(itemCount - 1, predictedIndex))
                                    offset = 0
                                }
                            
                        }
                )
        }
    }
}



