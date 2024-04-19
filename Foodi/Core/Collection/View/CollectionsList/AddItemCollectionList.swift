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
    var post: Post?
    let user: User
    
    
    init(user: User, post: Post? = nil) {
        self.user = user
        self.post = post
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(user: user, post: post))
    }
    var body: some View {
        VStack{
            if post != nil {
                if let item = viewModel.convertPostToCollectionItem() {
                    CollectionItemCell(item: item)
                }
            }
            CollectionsListView(viewModel: viewModel)
        }
        .onChange(of: viewModel.dismissListView) {
            if viewModel.dismissListView {
                dismiss()
                viewModel.dismissListView = false
            }
        }
    }
}

#Preview {
    AddItemCollectionList(user: DeveloperPreview.user, post: DeveloperPreview.posts[0])
}
