//
//  collectionSlideBar.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import Kingfisher
import FirebaseAuth
enum collectionSection {
    case grid, map
}

struct CollectionView: View {
    @State var currentSection: collectionSection = .grid
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @Environment(\.dismiss) var dismiss
    @State var showEditCollection: Bool = false
    @State var deletedCollection: Bool = false
    @State private var showingOptionsSheet = false
    @FocusState private var isNotesFocused: Bool
    @State var isDragging = false
    @State var dragDirection = "left"
    @State var showUserList = false
    var drag: some Gesture {
        DragGesture(minimumDistance: 14 )
            .onChanged { _ in self.isDragging = true }
            .onEnded { endedGesture in
                if (endedGesture.location.x - endedGesture.startLocation.x) > 0 {
                    self.dragDirection = "left"
                    
                    dismiss()
                }
            }
    }
    @State private var showCollaboratorsList = false
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    if let collection = collectionsViewModel.selectedCollection {
                        VStack {
                            // MARK: Cover Image
                            HStack(alignment: .bottom) {
                                if let cover = collection.coverImageUrl {
                                    CollageImage(tempImageUrls: [cover], width: 200)
                                } else if let tempImageUrls = collection.tempImageUrls {
                                    CollageImage(tempImageUrls: tempImageUrls, width: 200)
                                } else {
                                    Image(systemName: "folder")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .foregroundStyle(.black)
                                }
                            }
                            
                            // MARK: Title
                            HStack {
                                Text(collection.name)
                                    .font(.custom("MuseoSansRounded-300", size: 20))
                                    .bold()
                                    .foregroundStyle(.black)
                                
                                if isCollaborator(for: collection) {
                                    Image(systemName: "link")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // MARK: Username and Invite Button
                            HStack(spacing: 0) {
                                Text("by: ")
                                    .font(.custom("MuseoSansRounded-300", size: 18))
                                    .foregroundStyle(.black)
                                
                                NavigationLink(destination: ProfileView(uid: collection.uid)) {
                                    Text("@\(collection.username)")
                                        .font(.custom("MuseoSansRounded-500", size: 18))
                                        .foregroundStyle(.black)
                                }
                                
                                if !collection.collaborators.isEmpty {
                                    Button(action: {
                                        showCollaboratorsList = true
                                    }) {
                                        Text(" + \(collection.collaborators.count) \(pluralText(for: collection.collaborators.count, singular: "other", plural: "others"))")
                                            .font(.custom("MuseoSansRounded-300", size: 18))
                                            .foregroundStyle(.gray)
                                    }
                                }
                                // If the current user owns the collection, show the plus circle icon
                            }
                            
                            
                            if let description = collection.description, !description.isEmpty {
                                VStack {
                                    Text(description)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .foregroundStyle(.black)
                                }
                                .frame(width: UIScreen.main.bounds.width * 3 / 4)
                            }
                            
                            LikeButton(collection: collection, viewModel: collectionsViewModel)
                                .padding(.vertical, 2)
                            if let currentUser = Auth.auth().currentUser?.uid, currentUser == collection.uid {
                                    Button {
                                        showUserList = true
                                    } label: {
                                        HStack(spacing: 0){
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.gray)
                                            
                                            
                                            Text(" Add Collaborators")
                                                .font(.custom("MuseoSansRounded-500", size: 14))
                                                .foregroundStyle(.gray)
                                        }
                                }
                            }
                            // MARK: Grid and Map View Toggle
                            HStack(spacing: 0) {
                                Image(systemName: currentSection == .grid ? "square.grid.2x2.fill" : "square.grid.2x2")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 20)
                                    .onTapGesture {
                                        withAnimation {
                                            self.currentSection = .grid
                                        }
                                    }
                                    .modifier(UnderlineImageModifier(isSelected: currentSection == .grid))
                                    .frame(maxWidth: .infinity)
                                
                                Image(systemName: currentSection == .map ? "location.fill" : "location")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 22)
                                    .onTapGesture {

                                        withAnimation {
                                            self.currentSection = .map
                                        }
                                    }
                                    .modifier(UnderlineImageModifier(isSelected: currentSection == .map))
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            
                            // MARK: Section Logic
                            if currentSection == .map {
                                if #available(iOS 17, *) {
//                                    CollectionMapView(collectionsViewModel: collectionsViewModel)
                                }
                            } else if currentSection == .grid {
                                CollectionListView(collectionsViewModel: collectionsViewModel)
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button {
                                    collectionsViewModel.resetViewModel()
                                    dismiss()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .foregroundStyle(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.gray.opacity(0.5))
                                                .frame(width: 30, height: 30)
                                        )
                                        .padding()
                                }
                            }
                            
                            // MARK: Edit Button
                            ToolbarItem(placement: .topBarTrailing) {
                                if let currentUser = Auth.auth().currentUser?.uid,
                                   (currentUser == collection.uid || collection.collaborators.contains(currentUser)) {
                                    Button {
                                        showEditCollection.toggle()
                                    } label: {
                                        Text("Edit")
                                            .padding()
                                            .foregroundStyle(.black)
                                    }
                                } else {
                                    Button {
                                        showingOptionsSheet = true
                                    } label: {
                                        ZStack {
                                            Rectangle()
                                                .fill(.clear)
                                                .frame(width: 18, height: 14)
                                            Image(systemName: "ellipsis")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 6, height: 6)
                                                .foregroundStyle(.black)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: Notes View
                if let item = collectionsViewModel.notesPreview {
                    ItemNotesView(item: item, viewModel: collectionsViewModel)
                        .focused($isNotesFocused)
                        .onAppear {
                            isNotesFocused = true
                        }
                        
                }
            }
            .onAppear {
                Task {
                    await collectionsViewModel.checkIfUserLikedCollection()
                }
            }
            .gesture(drag)
            .sheet(isPresented: $showEditCollection) {
                EditCollectionView(collectionsViewModel: collectionsViewModel)
                    .onDisappear {
                        if collectionsViewModel.dismissCollectionView {
                            collectionsViewModel.dismissCollectionView = false
                            dismiss()
                        }
                    }
            }
            .sheet(isPresented: $showCollaboratorsList) {
                if let collection = collectionsViewModel.selectedCollection {
                    CollaboratorsListView(collaboratorIds: collection.collaborators)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
                }
            }
            
            .sheet(isPresented: $showingOptionsSheet) {
                if let selectedCollection = collectionsViewModel.selectedCollection {
                    CollectionOptionsSheet(collection: selectedCollection)
                        .presentationDetents([.height(UIScreen.main.bounds.height * 0.10)])
                }
            }
            .fullScreenCover(isPresented: $showUserList) {
                CollectionInviteUserList(collectionsViewModel: collectionsViewModel)
            }
        }
    }
    private func isCollaborator(for collection: Collection) -> Bool {
           return !collection.collaborators.isEmpty
       }
    private func pluralText(for count: Int, singular: String, plural: String) -> String {
        return count == 1 ? singular : plural
    }
    
}

struct LikeButton: View {
    let collection: Collection
    @ObservedObject var viewModel: CollectionsViewModel
    
    var body: some View {
        Button(action: {
            Task {
                if collection.didLike {
                    await viewModel.unlike(collection)
                } else {
                    await viewModel.like(collection)
                }
            }
        }) {
            HStack(spacing: 1){
                Image(systemName: collection.didLike ? "heart.fill" : "heart")
                    .foregroundColor(collection.didLike ? .red : .gray)
                Text("\(collection.likes)")
                    .foregroundColor(.gray)
            }
        }
    }
}
class CollaboratorsListViewModel: ObservableObject {
    @Published var collaborators: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedUser: User?

    func fetchCollaborators(collaboratorIds: [String]) {
        isLoading = true
        collaborators = [] // Clear existing collaborators

        Task {
            do {
                for id in collaboratorIds {
                    let user = try await UserService.shared.fetchUser(withUid: id)
                    await MainActor.run {
                        self.collaborators.append(user)
                    }
                }
                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct CollaboratorsListView: View {
    @StateObject private var viewModel = CollaboratorsListViewModel()
    @State private var searchText = ""
    let collaboratorIds: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var showUserProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading Collaborators...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if viewModel.collaborators.isEmpty {
                    emptyView
                } else {
                    collaboratorList
                }
            }
            .navigationTitle("Collaborators")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search collaborators")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onAppear {
            viewModel.fetchCollaborators(collaboratorIds: collaboratorIds)
        }
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.error.map { AlertItem(error: $0) } },
            set: { _ in viewModel.error = nil }
        )) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.error.localizedDescription))
        }
        .fullScreenCover(item: $viewModel.selectedUser) { user in
            NavigationStack{
                ProfileView(uid: user.id)
            }
        }
    }

    private var emptyView: some View {
        VStack {
            Image("Skip")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            Text("No Collaborators Found")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
        }
    }

    private var collaboratorList: some View {
        List {
            ForEach(filteredCollaborators) { user in
                CollaboratorRow(user: user)
                    .onTapGesture {
                        viewModel.selectedUser = user
                    }
            }
        }
        .listStyle(PlainListStyle())
    }

    private var filteredCollaborators: [User] {
        if searchText.isEmpty {
            return viewModel.collaborators
        } else {
            return viewModel.collaborators.filter { user in
                user.username.lowercased().contains(searchText.lowercased()) ||
                user.fullname.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct CollaboratorRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullname)
                    .font(.custom("MuseoSansRounded-500", size: 16))
                    .foregroundStyle(.black)

                Text("@\(user.username)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)

                locationText
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var locationText: some View {
        Text(locationString)
            .font(.system(size: 12))
            .foregroundColor(.gray)
    }

    private var locationString: String {
        if let city = user.location?.city, let state = user.location?.state {
            return "\(city), \(state)"
        } else if let city = user.location?.city {
            return city
        } else if let state = user.location?.state {
            return state
        } else {
            return "Location not available"
        }
    }
}
