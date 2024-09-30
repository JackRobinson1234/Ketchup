//
//  BookmarksListView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/15/24.
//

import SwiftUI
import Kingfisher
import FirebaseAuth

struct BookmarksListView: View {
    @StateObject private var viewModel = BookmarksViewModel()
    @State private var searchText = ""
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                FastCrossfadeFoodImageView()
            } else if viewModel.bookmarks.isEmpty {
                Text("No bookmarks yet")
                    .foregroundColor(.secondary)
            } else {
                VStack{
                    ForEach(viewModel.bookmarks) { bookmark in
                        BookmarkItemCell(bookmark: bookmark, viewModel: viewModel, profileViewModel: profileViewModel)
                    }

                }
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchBookmarks(uid: profileViewModel.user.id)
            }
        }
    }
    

    private func deleteBookmarks(at offsets: IndexSet) {
        Task {
            await viewModel.deleteBookmarks(at: offsets)
        }
    }
}

struct BookmarkItemCell: View {
    let bookmark: Bookmark
    @ObservedObject var viewModel: BookmarksViewModel
    @State private var showUnbookmarkAlert = false
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Bookmark icon
            if profileViewModel.user.id == Auth.auth().currentUser?.uid {
                Button(action: {
                    showUnbookmarkAlert = true
                }) {
                    Image(systemName: "bookmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color("Colors/AccentColor"))
                }
                .alert(isPresented: $showUnbookmarkAlert) {
                    Alert(
                        title: Text("Unbookmark Restaurant"),
                        message: Text("Are you sure you want to remove this bookmark?"),
                        primaryButton: .destructive(Text("Unbookmark")) {
                            Task {
                                await viewModel.deleteBookmark(bookmark)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            NavigationLink(destination: RestaurantProfileView(restaurantId: bookmark.id)) {
            // Restaurant image
            if let image = bookmark.image {
                KFImage(URL(string: image))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "fork.knife")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            VStack(alignment: .leading) {
                Text(bookmark.restaurantName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                if let city = bookmark.restaurantCity, let state = bookmark.restaurantState {
                    Text("\(city), \(state)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Text(getTimeElapsedString(from: bookmark.timestamp))
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
          
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(height: 72)
    }
}
@MainActor
class BookmarksViewModel: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var isLoading = false
    
    func fetchBookmarks(uid: String) async {
        isLoading = true
        do {
            bookmarks = try await UserService.shared.fetchUserBookmarks(uid: uid)
            isLoading = false
        } catch {
            //print("Error fetching bookmarks: \(error)")
            isLoading = false
        }
    }
    
    func deleteBookmark(_ bookmark: Bookmark) async {
        do {
            try await RestaurantService.shared.removeBookmark(for: bookmark.id)
            if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
                bookmarks.remove(at: index)
            }
        } catch {
            //print("Error deleting bookmark: \(error)")
        }
    }
    
    func deleteBookmarks(at offsets: IndexSet) async {
        for index in offsets {
            let bookmark = bookmarks[index]
            await deleteBookmark(bookmark)
        }
    }
}
