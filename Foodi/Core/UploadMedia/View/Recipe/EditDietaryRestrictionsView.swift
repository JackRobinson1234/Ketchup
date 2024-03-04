//
//  EditDietaryRestrictionsView.swift
//  Foodi
//
//  Created by Jack Robinson on 3/4/24.
//

import SwiftUI

struct EditDietaryRestrictionsView: View {
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack{
            //MARK: Title
            ScrollView{
                VStack{
                    HStack{
                        Text("Dietary Restrictions")
                            .font(.headline)
                            .padding()
                        Spacer()
                    }
                    //MARK: Adding Text Fields
                    ForEach($viewModel.dietaryRestrictions.indices, id: \.self) { index in
                        TextField("Add Dietary Restriction...", text: $viewModel.dietaryRestrictions[index], axis: .vertical)
                            .font(.subheadline)
                        Divider()
                    }.padding(.leading)
                    
                    //MARK: Adding Extra Restrictions
                    
                    
                    if $viewModel.dietaryRestrictions.count < 25 {
                        Button {
                            viewModel.addEmptyRestriction()
                        } label: {
                            VStack{
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                    .font(.subheadline)
                                    .opacity(viewModel.isLastRestrictionEmpty ? 0.5 : 1.0)
                                Text("Add Another Dietary Restriction")
                                    .font(.caption)
                                    .opacity(viewModel.isLastRestrictionEmpty ? 0.5 : 1.0)
                            }
                        }
                        .padding(.top, 10)
                        .disabled(viewModel.isLastRestrictionEmpty)
                    }
                    else {
                        Text("Maximim Ingredients Reached")
                            .font(.caption)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Add Dietary Restritions")
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}
#Preview {
    EditDietaryRestrictionsView(viewModel: UploadPostViewModel(service: UploadPostService(), restaurant: nil))
}
