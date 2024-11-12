//
//  MapFiltersView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/9/24.
//

import SwiftUI

//struct MapFiltersView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var selectedOption: MapFiltersViewOptions = .cuisine
//    @State private var cuisineText = ""
//    @ObservedObject var mapViewModel: MapViewModel
//    @ObservedObject var followingPostsMapViewModel: FollowingPostsMapViewModel
//    @State var selectedPrice: [String] = []
//    @State var selectedCuisines: [String] = []
//    @Binding var showFollowingPosts: Bool
//    init(mapViewModel: MapViewModel,followingPostsMapViewModel: FollowingPostsMapViewModel, showFollowingPosts: Binding<Bool> ) {
//        self.mapViewModel = mapViewModel
//        self.followingPostsMapViewModel = followingPostsMapViewModel
//        _selectedPrice = State(initialValue: mapViewModel.selectedPrice)
//        _selectedCuisines = State(initialValue: mapViewModel.selectedCuisines)
//        self._showFollowingPosts = showFollowingPosts
//    }
//    
//    var body: some View {
//        NavigationStack {
//            //MARK: Cuisine
//            VStack{
//                Button{
//                    mapViewModel.clearFilters()
//                } label: {
//                    Text("Remove all filters")
//                        .foregroundStyle(Color("Colors/AccentColor"))
//                }
//                
//                if selectedOption == .cuisine {
//                    VStack(alignment: .leading){
//                        MapCuisineFilter(selectedCuisines: $selectedCuisines)
//                    }
//                    .modifier(CollapsibleFilterViewModifier(frame: 260))
//                    .onTapGesture(count:2){
//                        withAnimation(.snappy){ selectedOption = .noneSelected}}
//                }
//                else {
//                    CollapsedPickerView(title: "Cuisine", emptyDescription: "Filter by Cuisine", count: selectedCuisines.count, singularDescription: "Cuisine Selected", pluralDescription: "Cuisines Selected")
//                        .onTapGesture{
//                            withAnimation(.snappy){ selectedOption = .cuisine}
//                        }
//                }
//            }
//            
//            //MARK: Price
//            VStack{
//                if selectedOption == .price {
//                    VStack(alignment: .leading){
//                        MapPriceFilter(selectedPrice: $selectedPrice)
//                    }
//                    .modifier(CollapsibleFilterViewModifier(frame: 210))
//                    .onTapGesture(count:2){
//                        withAnimation(.snappy){ selectedOption = .noneSelected}}
//                }
//                else {
//                    /// "Filter Price" if no options selected
//                    CollapsedPickerView(title: "Price", emptyDescription: "Filter by Price", count: selectedPrice.count, singularDescription: "Price Selected", pluralDescription: "Prices Selected")
//                        .onTapGesture{
//                            withAnimation(.snappy){ selectedOption = .price}
//                        }
//                }
//            }
//            //MARK: Dietary Restrictions
//            
//            Spacer()
//            //MARK: Navigation Title
//                .navigationTitle("Add Filters")
//                .navigationBarTitleDisplayMode(.inline)
//                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button {
//                            dismiss()
//                        } label: {
//                            Image(systemName: "xmark")
//                                .imageScale(.small)
//                                .foregroundColor(.black)
//                                .padding(6)
//                                .overlay(
//                                    Circle()
//                                        .stroke(lineWidth: 1.0)
//                                        .foregroundColor(.gray)
//                                )
//                        }
//                    }
//                    //MARK: Save Button
//                    ToolbarItem(placement: .topBarTrailing) {
//                        Button {
//                            saveFilters()
//                            dismiss()
//                        } label: {
//                            Text("Save")
//                                .foregroundColor(.blue)
//                                .padding(6)
//                        }
//                    }
//                }
//        }
//    }
//    //MARK: saveFilters
//    private func saveFilters() {
//        mapViewModel.selectedPrice = selectedPrice
//        followingPostsMapViewModel.selectedPrice = selectedPrice
//        mapViewModel.selectedCuisines = selectedCuisines
//        followingPostsMapViewModel.selectedCuisines = selectedCuisines
//        if showFollowingPosts{
//            Task {
//                await  followingPostsMapViewModel.fetchFollowingPosts()
//            }
//        } else {
//            Task {
//                await mapViewModel.fetchFilteredClusters()
//            }
//        }
//    }
//}
//
//
//
////MARK: Filter Options Enum
//enum MapFiltersViewOptions{
//    case cuisine
//    case price
//    case noneSelected
//}
struct MapFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var followingPostsMapViewModel: FollowingPostsMapViewModel
    @Binding var showFollowingPosts: Bool
    
    // Constants
    private let spacing: CGFloat = 20
    private let headerFont = Font.system(.title2, weight: .bold)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    filterSection("View Type") {
                        CustomToggle(showFollowingPosts: $showFollowingPosts){}
                            .padding(.horizontal)
                    }
                    
                    filterSection("Rating") {
                        FlowLayout(spacing: 8) {
                            ForEach([10.0, 9.0, 8.0, 7.0, 6.0, 5.0], id: \.self) { rating in
                                NewFilterButton(
                                    title: "\(String(format: "%.1f", rating))+",
                                    isSelected: mapViewModel.selectedRating == rating
                                ) {
                                    mapViewModel.selectedRating = mapViewModel.selectedRating == rating ? 0 : rating
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    filterSection("Price") {
                        FlowLayout(spacing: 8) {
                            ForEach(["$", "$$", "$$$", "$$$$"], id: \.self) { price in
                                NewFilterButton(
                                    title: price,
                                    isSelected: mapViewModel.selectedPrice.contains(price)
                                ) {
                                    if mapViewModel.selectedPrice.contains(price) {
                                        mapViewModel.selectedPrice.removeAll { $0 == price }
                                    } else {
                                        mapViewModel.selectedPrice.append(price)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    filterSection("Cuisine") {
                        FlowLayout(spacing: 8) {
                            ForEach(Cuisines.all, id: \.self) { cuisine in
                                NewFilterButton(
                                    title: cuisine,
                                    isSelected: mapViewModel.selectedCuisines.contains(cuisine)
                                ) {
                                    if mapViewModel.selectedCuisines.contains(cuisine) {
                                        mapViewModel.selectedCuisines.removeAll { $0 == cuisine }
                                    } else if mapViewModel.selectedCuisines.count < 5 {
                                        mapViewModel.selectedCuisines.append(cuisine)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        withAnimation {
                            mapViewModel.selectedRating = 0
                            mapViewModel.selectedCuisines = []
                            mapViewModel.selectedPrice = []
                        }
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(headerFont)
                .padding(.horizontal)
            
            content()
        }
    }
}

// Flow layout that arranges items in rows based on available width
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
