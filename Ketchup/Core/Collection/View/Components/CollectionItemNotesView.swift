//
//  CollectionItemNotesView.swift
//  Foodi
//
//  Created by Jack Robinson on 5/12/24.
//

import SwiftUI

struct ItemNotesView: View {
    var item: CollectionItem
    @ObservedObject var viewModel: CollectionsViewModel
    var body: some View {
        VStack {
                VStack {
                    HStack() {
                        Button {
                            viewModel.notesPreview = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 10)
                                .foregroundStyle(.black)
                                .padding()
                            
                        }
                        
                        Spacer()
                        
                        
                    }
                    CollectionItemCell(item: item, previewMode: true, viewModel: viewModel)
                    
                        .padding(.top, 10)
                        .frame(width: 330)
                    
                    Divider()
                    if let notes = item.notes {
                        HStack{
                            VStack{
                                Text("notes: ")
                                    .bold()
                                    .font(.custom("MuseoSansRounded-300", size: 16)) +
                                Text(notes)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                            }
                            Spacer()
                        }
                        .multilineTextAlignment(.leading)
                        .padding([.bottom, .horizontal])
                    }
                }
                .padding(.bottom, 5)
                .frame(width: 350)
                .background(Color.white)
                .cornerRadius(10)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
}

#Preview {
    ItemNotesView(item: DeveloperPreview.items[0], viewModel: CollectionsViewModel())
}
