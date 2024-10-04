//
//  ReferrerSearchView.swift
//  Ketchup
//
//  Created by Jack Robinson on 9/24/24.
//

import SwiftUI
import InstantSearchSwiftUI

struct ReferUserListView: View {
    @StateObject var viewModel = SearchViewModel(initialSearchConfig: .users)
    @ObservedObject var usernameRegistrationViewModel: UserRegistrationViewModel
    var debouncer = Debouncer(delay: 1.0)
    @State var selectedUser: User? = nil
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    @State var inSearchView = false

    var body: some View {
        NavigationStack{
            VStack(spacing: 0) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    ZStack(alignment: .leading) {
                        TextField("", text: $viewModel.searchQuery)
                            .focused($isSearchFocused)
                            .onTapGesture {
                                inSearchView = false
                            }
                            .submitLabel(.done)
                            .onSubmit {
                                dismissKeyboard()
                            }
                        if viewModel.searchQuery.isEmpty {
                            Text("Search")
                                .font(.custom("MuseoSansRounded-500", size: 16))
                                .foregroundStyle(.gray)
                        }
                    }
                    if !viewModel.searchQuery.isEmpty {
                        Button(action: {
                            viewModel.searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFocused = true
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 2)
                InfiniteList(viewModel.userHits, itemView: { hit in
                    Button{
                        usernameRegistrationViewModel.referrer = hit.object
                        dismiss()
                    } label: {
                        
                        UserCell(user: hit.object)
                            .padding()
                    }
                    
                    Divider()
                }, noResults: {
                    Text("No results found")
                        .foregroundStyle(.black)
                })
                .fullScreenCover(item: $selectedUser){user in
                    NavigationStack{
                        ProfileView(uid: user.id)
                    }
                }
                .navigationTitle("Select who referred you")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                    }
                }
                .onChange(of: viewModel.searchQuery) {newValue in
                    debouncer.schedule {
                        viewModel.notifyQueryChanged()
                    }
                }
            }
        }
    }
}
