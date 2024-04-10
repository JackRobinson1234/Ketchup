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
    var collection: Collection
    init(collection: Collection) {
        self.collection = collection
    }
    
    var body: some View {
        //MARK: Selecting Images
        NavigationStack{
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
                    //MapRestaurantProfileView(restaurant: restaurant)
                    
                }
                if currentSection == .grid {
                    CollectionGridView(collection: collection)
                }
            }
        }
    }
}
#Preview {
    CollectionView(collection: DeveloperPreview.collections[0])
}
