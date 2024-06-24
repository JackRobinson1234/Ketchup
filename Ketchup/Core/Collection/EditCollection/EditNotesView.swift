//
//  EditNotesView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

import SwiftUI

struct EditNotesView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var item: CollectionItem? // when this is nil, this view disappears
    var maxCharacters = 150
    @State var notes = ""
    @ObservedObject var viewModel: CollectionsViewModel
    @Binding var itemsPreview: [CollectionItem]
    var body: some View {
        ZStack {
            VStack {
                HStack{
                    Button{
                        item = nil
                    } label: {
                        Text("Cancel")
                    }
                    Spacer()
                }
                if let item = item {
                    CollectionItemCell(item: item, viewModel: viewModel)
                }
                
                ZStack(alignment: .topLeading) {
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)  // Adjust the height as needed
                        .padding(4)
                    
                    if notes.isEmpty {
                        Text("Add some notes...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 12)
                    }
                }
                .padding()
                HStack {
                    Spacer()
                    
                    Text("\(maxCharacters - notes.count) characters remaining")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                        .padding(.horizontal, 10)
                    
                        .foregroundStyle(.gray)
                        .padding()
                }
                .onChange(of: notes) {
                    if notes.count > maxCharacters {
                        notes = String(notes.prefix(maxCharacters))
                    }
                }
                Button{
                    // Replace the item in itemsPreview with the updated item
                    if var updatedItem = item {
                        updatedItem.notes = notes
                        
                        itemsPreview = itemsPreview.map { $0.id == updatedItem.id ? updatedItem : $0 }
                        ///appends the item to viewmodel.editItems
                        if let index = viewModel.editItems.firstIndex(where: { $0.id == updatedItem.id }) {
                            viewModel.editItems[index] = updatedItem
                        } else {
                            viewModel.editItems.append(updatedItem)
                        }
                    }
                    
                    // Dismiss the view
                    item = nil
                } label: {
                    Text("Add Notes")
                        .modifier(StandardButtonModifier(width: 250))
                }
                
            }
            .padding()
            .frame(width: 350)
            .background(Color.white)
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.8))
        .onAppear {
            if let itemNotes = item?.notes {
                notes = itemNotes
            } else {
                notes = ""
            }
        }
    }
}

#Preview {
    EditNotesView(item: .constant(DeveloperPreview.items[0]), viewModel: CollectionsViewModel(user: DeveloperPreview.user), itemsPreview: .constant([]))
}
