//
//  PostOptions.swift
//  Foodi
//
//  Created by Jack Robinson on 5/14/24.
//

//import SwiftUI
//
//struct PostOptions: View {
//
//    @ObservedObject var uploadViewModel: UploadViewModel
//    @Binding var isPickingRestaurant: Bool
//    @Binding var isAddingRecipe: Bool
//    
//    var body: some View {
//        VStack {
//            Divider()
//            if uploadViewModel.postType == .cooking {
//      
//                Button {
//                    isAddingRecipe = true
//                } label: {
//                    // ADD RECIPE
//                    
//                    if !uploadViewModel.hasRecipeDetailsChanged() {
//                        HStack {
//                            Image(systemName: "book.circle")
//                                .resizable()
//                                .foregroundColor(.primary)
//                                .frame(width: 40, height: 40, alignment: .center)
//                            
//                            Text("Add recipe")
//                                .foregroundColor(.primary)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "plus")
//                                .resizable()
//                                .foregroundColor(.gray)
//                                .frame(width: 15, height: 15)
//                        }
//                        .padding(.horizontal , 15)
//                        .padding(.vertical, 3)
//                    } else {
//                        HStack {
//                            Image(systemName: "book.circle")
//                                .resizable()
//                                .foregroundColor(.primary)
//                                .frame(width: 40, height: 40, alignment: .center)
//                            
//                            Text("Recipe Saved")
//                                .foregroundColor(.primary)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "checkmark.circle")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .foregroundColor(.green)
//                                .frame(width: 20, height: 20)
//                        }
//                        .padding(.horizontal , 15)
//                        .padding(.vertical, 3)
//                    }
//                    
//                    
//                }
//            } else if uploadViewModel.postType == .dining {
//                if let restaurant = uploadViewModel.restaurant {
//                    Button {
//                        isPickingRestaurant = true
//                    } label: {
//                        // REPLACE RESTAURANT
//                        HStack {
//                            RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .small)
//                                .frame(width: 40, height: 40, alignment: .center)
//                            
//                            Text(restaurant.name)
//                                .foregroundColor(.primary)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "checkmark.circle")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .foregroundColor(.green)
//                                .frame(width: 20, height: 20)
//                        }
//                        .padding(.horizontal , 15)
//                        .padding(.vertical, 3)
//                    }
//                } else {
//                    Button {
//                        isPickingRestaurant = true
//                    } label: {
//                        // ADD RESTAURANT
//                        HStack {
//                            Image(systemName: "fork.knife.circle")
//                                .resizable()
//                                .foregroundColor(.primary)
//                                .frame(width: 40, height: 40, alignment: .center)
//                            
//                            Text("Add restaurant")
//                                .foregroundColor(.primary)
//                            
//                            Spacer()
//                            
//                            Image(systemName: "plus")
//                                .resizable()
//                                .foregroundColor(.gray)
//                                .frame(width: 15, height: 15)
//                        }
//                        .padding(.horizontal , 15)
//                        .padding(.vertical, 3)
//                    }
//                }
//            }
//
//            Divider()
//
//        }
//    }
//}
//
//#Preview {
//    PostOptions(uploadViewModel: UploadViewModel(), isPickingRestaurant: .constant(false), isAddingRecipe: .constant(false))
//}
