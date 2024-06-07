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
    @State var selectedItem: CollectionItem?
    var body: some View {
        NavigationStack{
            ZStack{
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
                            .onTapGesture {
                                withAnimation {
                                    self.collectionItemOption = .atHome
                                }
                            }
                            .modifier(UnderlineImageModifier(isSelected: collectionItemOption == .atHome))
                        //.frame(maxWidth: .infinity)
                        
                    }
                    .padding(.bottom)
                    if collectionItemOption == .restaurants {
                        CollectionRestaurantSearch(collectionsViewModel: collectionsViewModel, selectedItem: $selectedItem)
                    }
                }
                if selectedItem != nil {
                    AddNotesView(item: $selectedItem, viewModel: collectionsViewModel)
                }
            }
        }
    }
}
#Preview {
    ItemSelectorView(collectionsViewModel: CollectionsViewModel(user: DeveloperPreview.user))
}
