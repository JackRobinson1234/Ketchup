//
//  MapFiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

struct MapFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var followingViewModel: FollowingPostsMapViewModel
    @Binding var showFollowingPosts: Bool
    
    // Constants
    private let spacing: CGFloat = 20
    private let headerFont = Font.system(.title2, weight: .bold)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    // View Type Section
                    filterSection("View Type") {
                        CustomToggle(showFollowingPosts: $showFollowingPosts) {
                            // Handle toggle change if needed
                        }
                        .padding(.horizontal)
                    }
                    
                    // Rating Filter Section
                    filterSection("Rating") {
                        FlowLayout(spacing: 8) {
                            ForEach([10.0, 9.0, 8.0, 7.0, 6.0, 5.0], id: \.self) { rating in
                                NewFilterButton(
                                    title: "\(String(format: "%.1f", rating))+",
                                    isSelected: mapViewModel.selectedRating == rating || followingViewModel.selectedRating == rating
                                ) {
                                    let isSelected = mapViewModel.selectedRating == rating
                                    // Update both view models
                                    mapViewModel.selectedRating = isSelected ? 0 : rating
                                    followingViewModel.selectedRating = isSelected ? 0 : rating
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Price Filter Section
                    filterSection("Price") {
                        FlowLayout(spacing: 8) {
                            ForEach(["$", "$$", "$$$", "$$$$"], id: \.self) { price in
                                NewFilterButton(
                                    title: price,
                                    isSelected: mapViewModel.selectedPrice.contains(price) || followingViewModel.selectedPrice.contains(price)
                                ) {
                                    if mapViewModel.selectedPrice.contains(price) {
                                        mapViewModel.selectedPrice.removeAll { $0 == price }
                                    } else {
                                        mapViewModel.selectedPrice.append(price)
                                    }
                                    if followingViewModel.selectedPrice.contains(price) {
                                        followingViewModel.selectedPrice.removeAll { $0 == price }
                                    } else {
                                        followingViewModel.selectedPrice.append(price)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Cuisine Filter Section
                    filterSection("Cuisine") {
                        FlowLayout(spacing: 8) {
                            ForEach(Cuisines.all, id: \.self) { cuisine in
                                NewFilterButton(
                                    title: cuisine,
                                    isSelected: mapViewModel.selectedCuisines.contains(cuisine) || followingViewModel.selectedCuisines.contains(cuisine)
                                ) {
                                    if mapViewModel.selectedCuisines.contains(cuisine) {
                                        mapViewModel.selectedCuisines.removeAll { $0 == cuisine }
                                    } else if mapViewModel.selectedCuisines.count < 5 {
                                        mapViewModel.selectedCuisines.append(cuisine)
                                    }
                                    if followingViewModel.selectedCuisines.contains(cuisine) {
                                        followingViewModel.selectedCuisines.removeAll { $0 == cuisine }
                                    } else if followingViewModel.selectedCuisines.count < 5 {
                                        followingViewModel.selectedCuisines.append(cuisine)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Reset Button
                ToolbarItem(placement: .navigationBarLeading) { // Move Reset to the left
                    Button("Reset") {
                        withAnimation {
                            // Reset filters in both view models
                            mapViewModel.selectedRating = 0
                            mapViewModel.selectedCuisines = []
                            mapViewModel.selectedPrice = []
                            followingViewModel.selectedRating = 0
                            followingViewModel.selectedCuisines = []
                            followingViewModel.selectedPrice = []
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // Done Button
                ToolbarItem(placement: .navigationBarTrailing) { // Move Done to the right
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Helper function to create filter sections
    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(headerFont)
                .padding(.horizontal)
            
            content()
        }
    }
}

// Custom Toggle between "All" and "Friends" views

// Individual Toggle Button used in CustomToggle

// NewFilterButton used for individual filter options


// FlowLayout to arrange filter buttons in a responsive grid
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for idx in subviews.indices {
            subviews[idx].place(
                at: CGPoint(x: bounds.minX + result.positions[idx].x,
                           y: bounds.minY + result.positions[idx].y),
                proposal: ProposedViewSize(result.sizes[idx])
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], sizes: [CGSize], size: CGSize) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next row
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            sizes.append(size)
            
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        
        return (positions, sizes, CGSize(width: maxWidth, height: currentY + rowHeight))
    }
}
struct NewFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("MuseoSansRounded-500", size: 14))
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.red : Color.clear)
                .foregroundColor(isSelected ? .white : Color.red)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red, lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }
}
