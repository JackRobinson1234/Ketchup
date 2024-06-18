//
//  CollectionRestaurantSearch.swift
//  Foodi
//
//  Created by Jack Robinson on 4/15/24.
//

import SwiftUI
import InstantSearchSwiftUI
struct CollectionRestaurantSearch: View {
    @StateObject var viewModel = RestaurantListViewModel()
    @Environment(\.dismiss) var dismiss
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    var debouncer = Debouncer(delay: 1.0)
    @State var selectedItem: CollectionItem? = nil
    @State var createRestaurantView = false
    @State var dismissSearchView: Bool = false
    
    
    var body: some View {
        NavigationStack{
            ZStack{
                VStack{
                    Button{
                        createRestaurantView.toggle()
                    } label: {
                        VStack{
                            Text("Can't find the restaurant you're looking for?")
                                .foregroundStyle(.gray)
                                .font(.footnote)
                            Text("Request a Restaurant")
                                .foregroundStyle(Color("Colors/AccentColor"))
                                .font(.footnote)
                        }
                    }
                    InfiniteList(viewModel.hits, itemView: { hit in
                        Button{
                            dismissKeyboard()
                            selectedItem = collectionsViewModel.convertRestaurantToCollectionItem(restaurant: hit.object)} label: {
                                RestaurantCell(restaurant: hit.object)
                                    .padding(.leading)
                            }
                        Divider()
                    }, noResults: {
                        Text("No results found")
                    })
                }
                if selectedItem != nil {
                    AddNotesView(item: $selectedItem, viewModel: collectionsViewModel)
                        .toolbar(.hidden)
                    
                }
                
            }
            
            
            
            
            .navigationTitle("Add to Collection")
            .searchable(text: $viewModel.searchQuery,
                        prompt: "Search")
            .toolbar {
                if selectedItem == nil {
                      ToolbarItem(placement: .topBarLeading) {
                          Button {
                              dismiss()
                          } label: {
                              Text("Cancel")
                          }
                      }
                  }
            }
            .toolbar(.hidden, for: .tabBar)
            .navigationBarBackButtonHidden()
            .onChange(of: viewModel.searchQuery) {
                debouncer.schedule {
                    viewModel.notifyQueryChanged()
                }
            }
            .onAppear{
                if collectionsViewModel.dismissListView {
                    collectionsViewModel.dismissListView = false
                    dismiss()
                    
                }
            }
            .fullScreenCover(isPresented: $createRestaurantView) {
                CollectionAddRestaurantView(collectionsViewModel: collectionsViewModel, dismissListView: $dismissSearchView)
                    .onDisappear{
                        if dismissSearchView{
                            dismiss()
                        
                    }
                }
            }
            
        }
    }
    
}
