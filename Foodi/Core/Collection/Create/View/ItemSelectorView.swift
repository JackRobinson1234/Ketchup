//
//  ItemSelectorView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
enum CollectionItemOption {
    case restaurants, atHome
}

struct ItemSelectorView: View {
    @State var collectionItemOption: CollectionItemOption = .restaurants
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var body: some View {
        VStack{
            HStack(spacing: 30) {
                Text("Restaurant")
                    .onTapGesture {
                        withAnimation {
                            self.collectionItemOption = .restaurants
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: collectionItemOption == .restaurants))
                //.frame(maxWidth: .infinity)
                
                Text("At Home")
                    .frame(width: 50, height: 25)
                
                    .onTapGesture {
                        withAnimation {
                            self.collectionItemOption = .atHome
                        }
                    }
                    .modifier(UnderlineImageModifier(isSelected: collectionItemOption == .atHome))
                //.frame(maxWidth: .infinity)
                
            }
            if collectionItemOption == .restaurants {
            CollectionRestaurantSearch(restaurantService: RestaurantService(), collectionsViewModel: collectionsViewModel)
            }
        }
    }
}
#Preview {
    ItemSelectorView(collectionsViewModel: CollectionsViewModel())
}
