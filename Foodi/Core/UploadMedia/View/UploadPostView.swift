//
//  UploadPostView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
 
struct UploadPostView: View {
    @ObservedObject var viewModel: UploadPostViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var tabIndex: Int
    @Binding var cover: Bool
    @State var showAddRecipe: Bool = false
    private let postType: PostType
    @State var showDietary: Bool = false
    @State private var showTimePicker = false
    private let restaurant: Restaurant?
    private let movie: Movie
    
    
    init(movie: Movie, viewModel: UploadPostViewModel, tabIndex: Binding<Int>, restaurant: Restaurant?, cover: Binding<Bool>, postType: PostType ) {
        self.restaurant = restaurant
        self.movie = movie
        self.viewModel = viewModel
        self._tabIndex = tabIndex
        self._cover = cover
        self.postType = postType
    }
    var body: some View {
        switch postType {
        case .restaurant:
                VStack {
                    ScrollView{
                        HStack() {
                            //MARK: Restaurant
                            if let restaurant{
                                SelectedRestaurantView(restaurant: restaurant)}
                            Spacer()
                            //MARK: Thumbnail
                            if let uiImage = MediaHelpers.generateThumbnail(path: movie.url.absoluteString) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 125)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        //MARK: Caption
                        TextField("Enter your caption...", text: $viewModel.caption, axis: .vertical)
                            .font(.subheadline)
                            .padding(.top, 60)
                            .onChange(of: viewModel.caption) {oldvalue, newValue in
                                // Limit the text to 150 characters
                                if newValue.count > 1000 {
                                    viewModel.caption = String(newValue.prefix(1000))
                                }}
                        HStack {
                            Spacer()
                            Text("\(viewModel.caption.count)/1000")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        Divider()
                        Spacer()
                    }
                    //MARK: Post Button
                    Button {
                        Task {
                            try await viewModel.uploadRestaurantPost()
                            if viewModel.uploadSuccess{
                            }
                            else if viewModel.uploadFailure{
                            }
                            viewModel.reset()
                            cover = false
                            tabIndex = 0
                        }
                    } label: {
                        Text(viewModel.isLoading ? "" : "Post")
                            .modifier(StandardButtonModifier())
                            .overlay {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                
                            }
                    }
                    .disabled(viewModel.isLoading)
                }
            
            .padding()
            .navigationTitle("Restaurant Post")
            .navigationBarTitleDisplayMode(.inline)
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
        case .recipe:
                VStack {
                    ScrollView{
                        HStack {
                            //MARK: Recipe Title
                            TextField("Add a Recipe Title...", text: $viewModel.recipeTitle, axis: .vertical)
                                .font(.title)
                            
                            
                            Spacer()
                            //MARK: thumbnail
                            if let uiImage = MediaHelpers.generateThumbnail(path: movie.url.absoluteString) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 125)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        //MARK: Recipe Caption
                        TextField("Enter your caption...", text: $viewModel.caption, axis: .vertical)
                            .font(.subheadline)
                            .padding(.top, 60)
                            .onChange(of: viewModel.caption) {oldvalue, newValue in
                                // Limit the text to 150 characters
                                if newValue.count > 1000 {
                                    viewModel.caption = String(newValue.prefix(1000))
                                }}
                        HStack {
                            Spacer()
                            Text("\(viewModel.caption.count)/1000")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        Divider()
                        //MARK: Recipe Cuisine
                        TextField("Enter the cuisine...", text: $viewModel.recipeCuisine, axis: .vertical)
                            .font(.subheadline)
                            .padding(.top, 30)
                            .onChange(of: viewModel.recipeCuisine) {oldvalue, newValue in
                                // Limit the text to 150 characters
                                if newValue.count > 1000 {
                                    viewModel.recipeCuisine = String(newValue.prefix(1000))
                                }}
                        Divider()
                        
                        // MARK: Recipe Dietary
                        Button{
                            showDietary.toggle()
                        } label: {
                            HStack{
                                VStack (alignment: .leading) {
                                    Text("Add Dietary Restrictions (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                if viewModel.dietaryRestrictions.count > 0 && !viewModel.dietaryRestrictions[0].isEmpty {
                                    Text("\(viewModel.dietaryRestrictions.joined(separator: ", "))")
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.black)
                                } else {
                                    Text("No Dietary Restrictions Added")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding(.top, 30)
                        Divider()
                        
                        //MARK: Add Recipe
                        Button{
                            showAddRecipe.toggle()
                        } label: {
                            HStack{
                                VStack (alignment: .leading) {
                                    Text("Add your Recipe (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    // if the ingredients, instructions, or viewModel is empty, then it won't show that the user edited the recipe.
                                    if viewModel.ingredients.count > 0 && !viewModel.ingredients[0].item.isEmpty ||
                                        viewModel.instructions.count > 0 && !viewModel.instructions[0].title.isEmpty
                                        
                                    {
                                        Text("Recipe Added")
                                            .font(.caption)
                                            .foregroundStyle(.black)
                                    }
                                    else {
                                        Text("No Recipe Added")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            
                        }
                        .padding(.top, 30)
                        Divider()
                        
                        //MARK: Recipe Time
                        Button{
                            showTimePicker.toggle()
                        } label: {
                            HStack{
                                VStack (alignment: .leading) {
                                    Text("Add Total Recipe Time...")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    // if hours/ minutes are 0, show correct logic
                                    if viewModel.recipeMinutes == 0 && viewModel.recipeHours == 0
                                        
                                    {Text("No Time Added")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    else {
                                        Text("\(viewModel.recipeHours) hours, \(viewModel.recipeMinutes) minutes")
                                            .font(.caption)
                                            .foregroundStyle(.black)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                        .padding(.top, 30)
                        
                        Divider()
                        /*
                            HStack {
                                // Hours Picker
                                Picker("Hours", selection: $viewModel.recipeHours) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)")
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                                .padding(.top, 30)
                                
                                Text("hours")
                                
                                // Minutes Picker
                                Picker("Minutes", selection: $viewModel.recipeMinutes) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)")
                                    }
                                }
                                .pickerStyle(WheelPickerStyle())
                                .frame(width: 80)
                                .padding(.top, 30)
                                
                                Text("minutes")
                            }
                            
                        */
                    }
                    Spacer()
                    Divider()
                
                    Button {
                        //MARK: Post Button
                        Task {
                            try await viewModel.uploadRecipePost()
                            if viewModel.uploadSuccess{
                                print("upload success")
                            }
                            else if viewModel.uploadFailure{
                            }
                            viewModel.reset()
                            cover = false
                            tabIndex = 0
                        }
                    } label: {
                        Text(viewModel.isLoading ? "" : "Post")
                            .modifier(StandardButtonModifier())
                            .overlay {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                }
                                
                            }
                    }
                    .disabled(viewModel.isLoading)
                
            }
            .sheet(isPresented: $showAddRecipe){EditRecipeView(viewModel: viewModel)}
            .sheet(isPresented: $showDietary){EditDietaryRestrictionsView(viewModel: viewModel)}
            .sheet(isPresented: $showTimePicker) {RecipeTimePicker(viewModel: viewModel)}
            .padding()
            .navigationTitle("Recipe Post")
            .navigationBarTitleDisplayMode(.inline)
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
            
        case .brand:
            Text("Hello")
        }
    }
}

/*#Preview {
    UploadPostView(movie: Movie(url: URL(string: "")!),
                   viewModel: UploadPostViewModel(service: UploadPostService(restaurantId: restaurants.id[)),
                   tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
} */
