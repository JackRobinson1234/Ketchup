//
//  AddNotesView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/13/24.
//

import SwiftUI

struct AddNotesView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var item: CollectionItem?
    var maxCharacters = 300
    @State var notes = ""
    @ObservedObject var viewModel: CollectionsViewModel
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
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }
                    
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
                    viewModel.notes = notes
                    if let item = item{
                        Task{
                            try await viewModel.addItemToCollection(collectionItem: item)
                        }
                    }
                    viewModel.dismissListView = true
                    dismiss()
                } label: {
                    Text("Add Item")
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
    }
    
}
#Preview {
    AddNotesView(item: .constant(DeveloperPreview.items[0]), viewModel: CollectionsViewModel())
}
