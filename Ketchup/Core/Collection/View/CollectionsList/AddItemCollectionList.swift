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
    @FocusState private var isCaptionEditorFocused: Bool
    @State private var isEditingCaption = false
    var post: Post?
    var restaurant: Restaurant?
    
    init(post: Post? = nil, restaurant: Restaurant? = nil) {
        self.post = post
        self.restaurant = restaurant
        self._viewModel = StateObject(wrappedValue: CollectionsViewModel(post: post, restaurant: restaurant))
    }
    var body: some View {
        NavigationStack{
            ZStack {
                ScrollView {
                    VStack{
                        if post != nil {
                            if let item = viewModel.convertPostToCollectionItem() {
                                CollectionItemCell(item: item, previewMode: true, viewModel: viewModel)
                                    .padding()
                            }
                        }
                        
                        else if restaurant != nil {
                            if let item = viewModel.convertRestaurantToCollectionItem() {
                                CollectionItemCell(item: item, previewMode: true, viewModel: viewModel)
                                    .padding()
                            }
                        }
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $viewModel.notes)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .frame(height: 75)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .cornerRadius(5)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            dismissKeyboard()
                                        }
                                    }
                                }
                            if viewModel.notes.isEmpty {
                                Text("Add some notes...")
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .foregroundColor(Color.gray)
                                    .padding(.horizontal, 25)
                                    .padding(.top, 8)
                            }
                        }
                        
                        CollectionsListView(viewModel: viewModel, user: AuthService.shared.userSession!)
                        Spacer()
                    }
                }
                
            }
            .onAppear{
                //print("initial viewModel post", viewModel.post)
                //print("initial viewModel restaurant", viewModel.restaurant)
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
            .navigationBarTitle("Add Restaurant to a Collection")
        }
    }
}

