//
//  UploadPostView.swift
//  Foodi
//
//  Created by Jack Robinson on 2/1/24.
//

import SwiftUI
import CurrencyField
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
    @State var media: MediaType
    /*private let priceFormatter: NumberFormatter = {
           let formatter = NumberFormatter()
           formatter.numberStyle = .currency
           return formatter
       }()*/
    
    init(viewModel: UploadPostViewModel, tabIndex: Binding<Int>, restaurant: Restaurant?, cover: Binding<Bool>, postType: PostType) {
        self.restaurant = restaurant
        self.viewModel = viewModel
        self._tabIndex = tabIndex
        self._cover = cover
        self.postType = postType
        self.media = viewModel.mediaPreview!
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
                        if let uiImage = MediaHelpers.generateThumbnail(path: viewModel.mediaPreview!.url.absoluteString) {
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
                            if newValue.count > 500 {
                                viewModel.caption = String(newValue.prefix(500))
                            }}
                    HStack {
                        Spacer()
                        Text("\(viewModel.caption.count)/500")
                            .foregroundColor(viewModel.caption.isEmpty ? .red : .gray)
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
                        VStack{
                            TextField("Add a Recipe Title...", text: $viewModel.recipeTitle, axis: .vertical)
                                .font(.title)
                                .onChange(of: viewModel.recipeTitle) {oldvalue, newValue in
                                    // Limit the text to 150 characters
                                    if newValue.count > 100 {
                                        viewModel.recipeTitle = String(newValue.prefix(100))
                                    }}
                            
                            HStack {
                                Spacer()
                                Text("\(viewModel.recipeTitle.count)/100")
                                    .foregroundColor(viewModel.recipeTitle.isEmpty ? .red : .gray)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                        Spacer()
                        //MARK: thumbnail
                        if let uiImage = MediaHelpers.generateThumbnail(path: media.url.absoluteString) {
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
                            if newValue.count > 500 {
                                viewModel.caption = String(newValue.prefix(500))
                            }}
                    HStack {
                        Spacer()
                        Text("\(viewModel.caption.count)/500")
                            .foregroundColor(viewModel.caption.isEmpty ? .red : .gray)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    Divider()
                    VStack{
                        //MARK: Recipe Cuisine
                        TextField("Enter the cuisine...", text: $viewModel.recipeCuisine, axis: .vertical)
                            .font(.subheadline)
                            .padding(.top, 30)
                            .onChange(of: viewModel.recipeCuisine) {oldvalue, newValue in
                                // Limit the text to 150 characters
                                if newValue.count > 50 {
                                    viewModel.recipeCuisine = String(newValue.prefix(50))
                                }}
                        HStack {
                            Spacer()
                            Text("\(viewModel.recipeCuisine.count)/50")
                                .foregroundColor(viewModel.recipeCuisine.isEmpty ? .red : .gray)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                    }
                    Divider()
                    
                    // MARK: Recipe Dietary
                    Button{
                        showDietary.toggle()
                    } label: {
                        HStack{
                            VStack (alignment: .leading) {
                                
                                if viewModel.dietaryRestrictions.count > 0 && !viewModel.dietaryRestrictions[0].isEmpty {
                                    Text("Add Dietary Restrictions (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    
                                    Text("\(viewModel.dietaryRestrictions.joined(separator: ", "))")
                                        .lineLimit(1)
                                        .font(.caption)
                                        .foregroundStyle(.black)
                                        .bold()
                                } else {
                                    Text("Add Dietary Restrictions (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("No Dietary Restrictions Added")
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
                    
                    //MARK: Add Recipe
                    Button{
                        showAddRecipe.toggle()
                    } label: {
                        HStack{
                            VStack (alignment: .leading) {
                                
                                // if the ingredients, instructions, or viewModel is empty, then it won't show that the user edited the recipe.
                                if viewModel.ingredients.count > 0 && !viewModel.ingredients[0].item.isEmpty ||
                                    viewModel.instructions.count > 0 && !viewModel.instructions[0].title.isEmpty
                                    
                                {
                                    Text("Add your Recipe (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    Text("Recipe Added")
                                        .font(.caption)
                                        .foregroundStyle(.black)
                                }
                                else {
                                    Text("Add your Recipe (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
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
                                
                                // if hours/ minutes are 0, show correct logic
                                if viewModel.recipeMinutes == 0 && viewModel.recipeHours == 0{
                                    Text("Add Total Recipe Time (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    
                                    Text("No Time Added")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                else {
                                    Text("Add Total Recipe Time (Optional)")
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    
                                    Text("\(viewModel.recipeHours) hours, \(viewModel.recipeMinutes) minutes")
                                        .font(.caption)
                                        .foregroundStyle(.black)
                                        .bold()
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding(.top, 30)
                    
                    Divider()
                    
                }
                Spacer()
                
                Button {
                    //MARK: Post Button
                    Task {
                        try await viewModel.uploadRecipePost()
                        if viewModel.uploadSuccess{
                            print("DEBUG: upload success")
                        }
                        else if viewModel.uploadFailure{
                            print("DEBUG: Mission failed, we'll get em next time")
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
            VStack {
                ScrollView{
                    HStack {
                        //MARK: Recipe Title
                        VStack{
                            TextField("Add a Brand...", text: $viewModel.brandTitle, axis: .vertical)
                                .font(.title)
                                .onChange(of: viewModel.brandTitle) {oldValue, newValue in
                                    // Limit the text to 150 characters
                                    if newValue.count > 100 {
                                        viewModel.brandTitle = String(newValue.prefix(100))
                                    }}
                            
                            HStack {
                                Spacer()
                                Text("\(viewModel.brandTitle.count)/100")
                                    .foregroundColor(viewModel.brandTitle.isEmpty ? .red : .gray)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                        Spacer()
                        //MARK: thumbnail
                        if let uiImage = MediaHelpers.generateThumbnail(path: viewModel.mediaPreview!.url.absoluteString) {
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
                            if newValue.count > 500 {
                                viewModel.caption = String(newValue.prefix(500))
                            }}
                    HStack {
                        Spacer()
                        Text("\(viewModel.caption.count)/500")
                            .foregroundColor(viewModel.caption.isEmpty ? .red : .gray)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    Divider()
                    VStack{
                        //MARK: Recipe Cuisine
                        HStack{
                            Text("Price: ")
                                .font(.subheadline)
                                .foregroundStyle(viewModel.brandPrice > 0 ? .black : .gray)
                            CurrencyField(value: $viewModel.brandPrice)
                                .font(.subheadline)
                                .foregroundStyle(viewModel.brandPrice > 0 ? .black : .gray)
                            Spacer()
                                
                        }
                        .padding(.top, 20)
                    }
                    Divider()
                    }
                Spacer()
                Button {
                    //MARK: Post Button
                    Task {
                        try await viewModel.uploadBrandPost()
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
            .padding(.horizontal)
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
        }
    }
}

/*#Preview {
    UploadPostView(movie: Movie(url: URL(string: "")!),
                   viewModel: UploadPostViewModel(service: UploadPostService(restaurantId: restaurants.id[)),
                   tabIndex: .constant(0), restaurant: DeveloperPreview.restaurants[0])
} */
