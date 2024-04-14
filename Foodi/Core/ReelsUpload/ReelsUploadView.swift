//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Joe Ciminelli on 4/6/24.
//

import SwiftUI

struct ReelsUploadView: View {
    
    //@ObservedObject var cameraModel: ReelsCameraViewModel
    @State var caption: String = ""
    @State var postType: String = "At Home Post"
    
    @State private var selection = "Select Post Type"
    let postTypeOptions = ["At Home Post", "Going out Post"]

    @State private var isEditingCaption = false
    @FocusState private var isCaptionEditorFocused: Bool
    @State var isPickingRestaurant = false
    @State var selectedRestaurant: Restaurant?
    
    
    
    var body: some View {
        
            ZStack {
                VStack {
                    
                    Rectangle()
                        .fill(.green)
                        .cornerRadius(30)
                        .frame(width: 200, height: 300)
                        .padding(.vertical)

                    
                    Button(action: {
                        self.isEditingCaption = true
                    }) {
                        CaptionBox(caption: $caption, isEditingCaption: $isEditingCaption)
                    }
                    PostOptions(isPickingRestaurant: $isPickingRestaurant, selectedRestaurant: $selectedRestaurant)
                }
                //.blur(radius: dropdownShown ? 10 : 0)
                
                if isEditingCaption {
                    CaptionEditorView(caption: $caption, isEditingCaption: $isEditingCaption)
                        .focused($isCaptionEditorFocused) // Connects the focus state to the editor view
                        .onAppear {
                            isCaptionEditorFocused = true // Automatically focuses the TextEditor when it appears
                        }
                }
            }
            .navigationTitle(selection)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                ForEach(postTypeOptions, id: \.self) { posttype in
                    Button {
                        selection = posttype
                    } label: {
                        if selection == posttype {
                            HStack {
                                Text(posttype)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                
                                Spacer()
                                
                                Image(systemName: "checkmark")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        } else {
                            Text(posttype)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                
                        }
                    }
                }
            }
            .preferredColorScheme(.light)
            //POSS Check if keyboard is active here
            .onTapGesture {
                dismissKeyboard()
            }
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height > 50 {
                        dismissKeyboard()
                    }
                }
            )
            .navigationDestination(isPresented: $isPickingRestaurant) {
                SelectRestaurantListView(selectedRestaurant: $selectedRestaurant, isPickingRestaurant: $isPickingRestaurant)
                    .navigationTitle("Select Restaurant")
            }
    }
    
    
    // Dismiss keyboard method
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    
}

struct CaptionBox: View {
    
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    let maxCharacters = 150
    
    var body: some View {
        VStack {
            
            ScrollView {
                ZStack(alignment: .leading) {
                    
                    TextEditor(text: $caption)
                        .foregroundColor(caption.isEmpty ? .clear : .primary) // Hide text editor text when empty and showing placeholder
                        .disabled(true)  // Disables editing directly in this view
                        .frame(maxHeight: .infinity) // Allows for flexible height
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            isEditingCaption = true // Activate editing mode
                        }
                    
                    if caption.isEmpty {
                        Text("Enter caption...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
            
            HStack {
                Spacer()
                Text("\(maxCharacters - caption.count) characters remaining")
                    .font(.caption)
                    .foregroundColor(caption.count > maxCharacters ? .red : .gray)
                    .padding(.horizontal, 10)
            }
        }
    }
}

struct CaptionEditorView: View {
    
    @Binding var caption: String
    @Binding var isEditingCaption: Bool
    let maxCharacters = 150
    @FocusState var isFocused: Bool
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    
                    HStack() {
                        Text("Caption")
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            isEditingCaption = false
                            isFocused = false
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                
                        }
                        .padding(8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        
                    }
                    .padding(.top, 10)
                    .frame(width: 330)
                    
                    Divider()
                    
                    TextEditor(text: $caption)
                        .font(.subheadline)
                        .background(Color.white)
                        .frame(width: 330, height: 150)
                        .focused($isFocused)
                    
                    HStack {
                        Spacer()
                        
                        Text("\(maxCharacters - caption.count) characters remaining")
                            .font(.caption)
                            .foregroundColor(caption.count > maxCharacters ? .red : .gray)
                            .padding(.horizontal, 10)
                    }
                    
                }
                .onChange(of: caption) {
                    if caption.count > maxCharacters {
                        caption = String(caption.prefix(maxCharacters))
                    }
                }
                .padding(.bottom, 5)
                .frame(width: 350)
                .background(Color.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.8))
    }
}

struct PostOptions: View {
    @State var caption: String = ""
    @State var isEditingCaption = false
    @Binding var isPickingRestaurant: Bool
    @Binding var selectedRestaurant: Restaurant?
    
    var body: some View {
        VStack {
            Divider()
            if let restaurant = selectedRestaurant {
                Button {
                    isPickingRestaurant = true
                } label: {
                    HStack {
                        RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .small)
                            .frame(width: 40, height: 40, alignment: .center)
                        
                        Text(restaurant.name)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.green)
                            .frame(width: 20, height: 20)
                    }
                    .padding(.horizontal , 15)
                    .padding(.vertical, 3)
                }
            } else {
                Button {
                    isPickingRestaurant = true
                } label: {
                    // ADD RESTAURANT
                    HStack {
                        Image(systemName: "fork.knife.circle")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40, alignment: .center)
                        
                        Text("Add restaurant")
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Image(systemName: "plus")
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 15, height: 15)
                    }
                    .padding(.horizontal , 15)
                    .padding(.vertical, 3)
                }
            }
            
            Divider()
            // TAG USER
            HStack {
                Image(systemName: "person.badge.plus")
                    .resizable()
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40, alignment: .center)
                
                Text("Tag User")
                
                Spacer()
                
                Image(systemName: "plus")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 15, height: 15)
            }
            .padding(.horizontal , 15)
            .padding(.vertical, 3)
            Divider()
            
            HStack {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .resizable()
                    .foregroundColor(.black)
                    .scaledToFit()
                    .frame(width: 40, height: 35, alignment: .center)
                    .frame(width: 40, height: 40, alignment: .center)
                
                Text("Add to collection")
                
                Spacer()
                
                Image(systemName: "plus")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 15, height: 15)
                
            }
            .padding(.horizontal , 15)
            .padding(.vertical, 3)
            
            Divider()
        }
    }
}

struct SelectRestaurantListView: View {

    @StateObject var viewModel = RestaurantListViewModel(restaurantService: RestaurantService())
    @State private var searchText = ""
    @Binding var selectedRestaurant: Restaurant?
    @State var isLoading: Bool = true
    @Binding var isPickingRestaurant: Bool


    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .onAppear {
                        Task {
                            try await viewModel.fetchRestaurants()
                            isLoading = false
                        }
                    }
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.restaurants) { restaurant in
                            Button(action: {
                                self.selectedRestaurant = restaurant
                                isPickingRestaurant = false
                            }) {
                                RestaurantCell(restaurant: restaurant)
                                    .padding(3)
                            }
                        }
                    }
                }
                .background(.white)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            }
        }
    }
}

#Preview {
    ReelsUploadView()
}

