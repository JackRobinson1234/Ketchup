//
//  collectionSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI

enum collectionSection {
    case grid, map
}

struct CollectionView: View {
    @State var currentSection: collectionSection = .grid
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        //MARK: Selecting Images
        NavigationStack{
            if let collection = collectionsViewModel.selectedCollection {
                VStack{
                    Text(collection.name)
                        .font(.title)
                        .bold()
                    Text("by: @\(collection.username)")
                        .font(.title3)
                    if let description = collection.description {
                        Text(description)
                            .font(.subheadline)
                    }
                    // MARK: Grid View
                    HStack(spacing: 0) {
                        Image(systemName: currentSection == .grid ? "square.grid.2x2.fill" : "square.grid.2x2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 20)
                        
                            .onTapGesture {
                                withAnimation {
                                    self.currentSection = .grid
                                }
                            }
                            .modifier(UnderlineImageModifier(isSelected: currentSection == .grid))
                            .frame(maxWidth: .infinity)
                        
                        //MARK: Location View
                        Image(systemName: currentSection == .map ? "location.fill" : "location")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 22)
                        
                            .onTapGesture {
                                withAnimation {
                                    self.currentSection = .map
                                }
                            }
                            .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    // MARK: Section Logic
                    if currentSection == .map {
                        CollectionMapView(collectionsViewModel: collectionsViewModel)
                        
                    }
                    if currentSection == .grid {
                        CollectionGridView(collectionsViewModel: collectionsViewModel)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.5)) // Adjust the opacity as needed
                                        .frame(width: 30, height: 30) // Adjust the size as needed
                                )
                                .padding()
                        }
                    }
                }
            }
        }
    }
}
#Preview {
    CollectionView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}
