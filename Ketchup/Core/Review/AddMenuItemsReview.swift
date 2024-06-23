//
//  AddMenuItemsReview.swift
//  Foodi
//
//  Created by Jack Robinson on 5/20/24.
//

import SwiftUI

struct AddMenuItemsReview: View {
    @State var favoriteMenuItem: String = ""
    @Binding var favoriteMenuItems: [String]
    @FocusState private var isTextFieldFocused: Bool
    var maxMenuItemCharacters: Int = 50
    var maxFavoriteMenuItems: Int = 5
    var body: some View {
        VStack{
            if !favoriteMenuItems.isEmpty {
                ScrollView(.horizontal) {
                    VStack {
                        ForEach(favoriteMenuItems, id: \.self) { item in
                            
                            HStack{
                                HStack {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color("Colors/AccentColor"))
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                removeItem(item)
                                            }
                                        }
                                    Text(item)
                                        .font(.custom("MuseoSans-500", size: 12))
                                }
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                                Spacer()
                            }
                            
                            
                        }
                        
                    }
                    .padding()
                }
            }
            HStack {
                TextField("Add a favorite menu item", text: $favoriteMenuItem, onCommit: {
                    addItem()
                    
                })
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            dismissKeyboard()
                        }
                    }
                }
                
                
                .frame(height:44)
                .padding(.horizontal)
                .font(.custom("MuseoSans-500", size: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1.0)
                        .foregroundStyle(Color(.systemGray4))
                )
                .focused($isTextFieldFocused)
                .onChange(of: favoriteMenuItem) {
                    if favoriteMenuItem.count > maxMenuItemCharacters {
                        favoriteMenuItem = String(favoriteMenuItem.prefix(maxMenuItemCharacters))
                    }
                }
                
                
                Button(action: addItem) {
                    Image(systemName:"plus")
                        .frame(height:44)
                        .foregroundColor(favoriteMenuItem.isEmpty ? .gray : .primary)
                        .cornerRadius(5)
                    
                }
                .disabled(favoriteMenuItem.isEmpty || favoriteMenuItems.count >= maxFavoriteMenuItems)
                
                
                .padding(.horizontal)
            }
            .padding(.horizontal)
            .onAppear {
                        isTextFieldFocused = true
                    }
            Spacer()
        }
        .navigationBarBackButtonHidden()
        .modifier(BackButtonModifier())
        .navigationTitle("Add Favorite Menu Items (Max 5)")
    }
    private func addItem() {
        guard !favoriteMenuItem.isEmpty else { return }
        favoriteMenuItems.append(favoriteMenuItem)
        favoriteMenuItem = ""
    }
    private func removeItem(_ item: String) {
        favoriteMenuItems.removeAll { $0 == item }
    }
}

#Preview {
    AddMenuItemsReview(favoriteMenuItems: .constant([]))
}
