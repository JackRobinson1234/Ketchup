//
//  SwiftUIView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI

struct AddItemCollectionList: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CollectionsViewModel
    let user: User
    var post: Post?
    var restaurant: Restaurant?
    
    
    init(user: User, post: Post? = nil, restaurant: Restaurant? = nil) {
        self.user = user
        self.post = post
        self.restaurant = restaurant
        print(restaurant)
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(user: user, post: post, restaurant: restaurant))
    }
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack{
                    if post != nil {
                        if let item = viewModel.convertPostToCollectionItem() {
                            CollectionItemCell(item: item)
                                .padding()
                        }
                    }
                    
                    else if restaurant != nil {
                        if let item = viewModel.convertRestaurantToCollectionItem() {
                            CollectionItemCell(item: item)
                                .padding()
                        }
                    }
                    CollectionsListView(viewModel: viewModel)
                    Spacer()
                }
            }
            .onChange(of: viewModel.dismissListView) {
                if viewModel.dismissListView {
                    dismiss()
                    viewModel.dismissListView = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle(post?.postType == "restaurant" ? "Add Restaurant to a Collection" : "Add Post to a Collection")
            .navigationBarTitle("Add Restaurant to a Collection")
        }
    }
}
#Preview {
    AddItemCollectionList(user: DeveloperPreview.user, post: DeveloperPreview.posts[0])
}
