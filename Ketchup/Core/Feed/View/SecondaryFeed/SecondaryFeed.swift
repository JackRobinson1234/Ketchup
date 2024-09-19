//
//  PrimaryFeed.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/26/24.
//

import SwiftUI

struct SecondaryFeedView: View {
    @ObservedObject var viewModel: FeedViewModel
    @State var scrollPosition: String?
    @State private var previousScrollPosition: String?
    @State private var showFilters = false
    @State private var isLoading = true
    @State private var selectedFeed: FeedType = .discover
    @State var pauseVideo = false
    @StateObject var filtersViewModel: FiltersViewModel
    @Environment(\.dismiss) var dismiss
    private var hideFeedOptions: Bool
    @State var startingPostId: String?
    private var titleText: String
    @State private var showSuccessMessage = false
    var checkLikes: Bool
    @State private var currentIndex: Int = 0
    @State private var itemCount: Int = 0
    private var filteredPosts: [Post] {
        viewModel.posts.filter { hasValidMedia($0) }
    }

    init(viewModel: FeedViewModel, hideFeedOptions: Bool = false, initialScrollPosition: String? = nil, titleText: String = "", checkLikes: Bool = false) {
        self.viewModel = viewModel
        self._filtersViewModel = StateObject(wrappedValue: FiltersViewModel(feedViewModel: viewModel))
        self.hideFeedOptions = hideFeedOptions
        self._scrollPosition = State(initialValue: initialScrollPosition)
        self.titleText = titleText
        self.checkLikes = checkLikes
        self.startingPostId = viewModel.startingPostId

        // Initialize currentIndex based on initialScrollPosition
        if let initialScrollPosition = initialScrollPosition,
           let index = filteredPosts.firstIndex(where: { $0.id == initialScrollPosition }) {
            self._currentIndex = State(initialValue: index)
        }

        self._itemCount = State(initialValue: filteredPosts.count)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VerticalPagingScrollView(
                itemHeight: UIScreen.main.bounds.height,
                itemSpacing: 0,
                itemCount: $itemCount,
                currentIndex: $currentIndex
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(filteredPosts.enumerated()), id: \.element.id) { index, post in
                        let postBinding = Binding<Post>(
                            get: { post },
                            set: { _ in }
                        )
                        ZStack {
                            FeedCell(
                                post: postBinding,
                                viewModel: viewModel,
                                scrollPosition: $scrollPosition,
                                pauseVideo: $pauseVideo,
                                hideFeedOptions: hideFeedOptions,
                                checkLikes: checkLikes
                            )
                        }
                        .ignoresSafeArea(.all)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .onAppear {
                            scrollPosition = post.id

                            // Use totalIndex from viewModel.posts
                            if !hideFeedOptions,
                               let totalIndex = viewModel.posts.firstIndex(where: { $0.id == post.id }),
                               totalIndex >= viewModel.posts.count - 5 {
                                print("Attempting to load more content at total index \(totalIndex)")
                                Task {
                                    await viewModel.loadMoreContentIfNeeded(currentPost: post.id)
                                }
                            }
                        }
                        .id(post.id)
                    }
                }
            }
            .onChange(of: currentIndex) { newIndex in
                handleScrollChange(newIndex: newIndex)
            }
            .onChange(of: viewModel.posts) { newValue in
                let newFilteredPosts = newValue.filter { hasValidMedia($0) }
                itemCount = newFilteredPosts.count
                print("DEBUG: Posts updated: new itemCount = \(itemCount)")
                
                // Update currentIndex based on scrollPosition
                if let scrollPosition = scrollPosition,
                   let index = newFilteredPosts.firstIndex(where: { $0.id == scrollPosition }) {
                    currentIndex = index
                } else {
                    // If the current scroll position is no longer valid, reset to the first item
                    currentIndex = 0
                    scrollPosition = newFilteredPosts.first?.id
                }
                
                print("DEBUG: Updated currentIndex to \(currentIndex), scrollPosition to \(scrollPosition ?? "nil")")
            }


            // Your existing top navigation and overlays
            if !hideFeedOptions {
                HStack(spacing: 0) {
                    Button {
                        if let scrollPosition = scrollPosition {
                            viewModel.initialPrimaryScrollPosition = scrollPosition
                        }
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
                    .frame(width: 60)

                    Spacer()

                    Image("KetchupTextRed")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 17)

                    Spacer()
                    Color.clear
                        .frame(width: 60, height: 17)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 55)
                .padding(.horizontal, 20)
                .foregroundStyle(.black)
                .padding(.bottom, 10)
            } else {
                HStack {
                    Button {
                        viewModel.initialPrimaryScrollPosition = scrollPosition
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(width: 40, height: 40)
                            )
                            .padding()
                    }
                    Spacer()

                    Text(titleText)
                        .foregroundStyle(.black)
                        .font(.custom("MuseoSansRounded-300", size: 18))
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Spacer()
                    Rectangle()
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.clear)
                }
                .padding(30)
                .padding(.vertical)
            }
        }
        .overlay {
            // Your existing overlays
        }
        .onChange(of: scrollPosition) { newPostId in
            if let oldPostId = previousScrollPosition {
                if let oldIndex = filteredPosts.firstIndex(where: { $0.id == oldPostId }),
                   let newIndex = filteredPosts.firstIndex(where: { $0.id == newPostId }) {
                    if newIndex > oldIndex {
                        viewModel.updateCache(scrollPosition: newPostId)
                        if !hideFeedOptions,
                           let totalIndex = viewModel.posts.firstIndex(where: { $0.id == newPostId }),
                           totalIndex >= viewModel.posts.count - 5 {
                            print("onChange of scrollPosition: Reached near end of posts at index \(totalIndex). Loading more content.")
                            Task {
                                await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
                            }
                        }
                    }
                }
            } else {
                // Handle the initial case where there is no previous scroll position
                viewModel.updateCache(scrollPosition: newPostId)
            }
            previousScrollPosition = newPostId
        }
        .background(Color("Colors/HingeGray"))
        .ignoresSafeArea()
        .navigationDestination(for: PostUser.self) { user in
            ProfileView(uid: user.id)
        }
        .navigationDestination(for: PostRestaurant.self) { restaurant in
            RestaurantProfileView(restaurantId: restaurant.id)
        }
        .onChange(of: showFilters) { newValue in
            pauseVideo = newValue
        }
        .fullScreenCover(isPresented: $showFilters) {
            FiltersView(filtersViewModel: filtersViewModel)
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.showPostAlert) { newValue in
            if newValue {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessMessage = false
                }
            }
        }
    }

    private func handleScrollChange(newIndex: Int) {
        print("DEBUG: Entering handleScrollChange with newIndex: \(newIndex)")
        let posts = filteredPosts
        guard newIndex < posts.count else {
            print("DEBUG: handleScrollChange: newIndex \(newIndex) is out of bounds (posts count: \(posts.count))")
            return
        }
        let newPostId = posts[newIndex].id
        let oldPostId = scrollPosition
        scrollPosition = newPostId

        print("DEBUG: handleScrollChange: oldPostId = \(String(describing: oldPostId)), newPostId = \(newPostId)")

        viewModel.updateCache(scrollPosition: newPostId)
        print("DEBUG: Updated cache for newPostId: \(newPostId)")

        if !hideFeedOptions {
            print("DEBUG: Feed options not hidden, attempting to load more content")
            Task {
                await viewModel.loadMoreContentIfNeeded(currentPost: newPostId)
            }
        } else {
            print("DEBUG: Feed options hidden, not loading more content")
        }
        print("DEBUG: Exiting handleScrollChange")
    }


    private func hasValidMedia(_ post: Post) -> Bool {
        switch post.mediaType {
        case .mixed:
            return post.mixedMediaUrls?.isEmpty == false
        case .video:
            return !post.mediaUrls.isEmpty
        case .photo:
            return !post.mediaUrls.isEmpty
        case .written:
            return false
        }
    }
}

// Your custom VerticalPagingScrollView remains the same

struct VerticalPagingScrollView<Content: View>: UIViewRepresentable {
    let content: () -> Content
    let itemHeight: CGFloat
    let itemSpacing: CGFloat
    @Binding var currentIndex: Int
    @Binding var itemCount: Int

    init(
        itemHeight: CGFloat,
        itemSpacing: CGFloat = 0,
        itemCount: Binding<Int>,
        currentIndex: Binding<Int>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.itemHeight = itemHeight
        self.itemSpacing = itemSpacing
        self._itemCount = itemCount
        self._currentIndex = currentIndex
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true // Keep this for manual paging control
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator
        scrollView.decelerationRate = .fast // Adjust deceleration rate for smoothness
        scrollView.bounces = false

        let hostingController = UIHostingController(rootView: content())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hostingController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        let verticalInset = (UIScreen.main.bounds.height - itemHeight) / 2
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0)
        let initialOffsetY = CGFloat(currentIndex) * (itemHeight + itemSpacing) - scrollView.contentInset.top
        scrollView.contentOffset = CGPoint(x: 0, y: initialOffsetY)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        let totalItemHeight = itemHeight + itemSpacing
        let totalHeight = CGFloat(itemCount) * totalItemHeight - itemSpacing
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: totalHeight)

        context.coordinator.hostingController.rootView = content()

        if let hostingView = context.coordinator.hostingController.view {
            hostingView.frame = CGRect(origin: .zero, size: CGSize(width: scrollView.frame.size.width, height: totalHeight))
        }

        let targetY = CGFloat(currentIndex) * totalItemHeight - scrollView.contentInset.top
        if abs(scrollView.contentOffset.y - targetY) > 0.5 {
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) {
                scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
            }
        }

        print("VerticalPagingScrollView updated: itemCount = \(itemCount), currentIndex = \(currentIndex)")
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: VerticalPagingScrollView
        var hostingController: UIHostingController<Content>!

        init(_ parent: VerticalPagingScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let pageHeight = parent.itemHeight + parent.itemSpacing
            let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
            let index = Int(round(offsetY / pageHeight))
            
            if index != parent.currentIndex {
                DispatchQueue.main.async {
                    self.parent.currentIndex = max(0, min(index, self.parent.itemCount - 1))
                }
            }
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            let pageHeight = parent.itemHeight + parent.itemSpacing
            let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
            var index = Int(round(offsetY / pageHeight))

            if velocity.y > 0.2 {
                index = min(index + 1, parent.itemCount - 1)
            } else if velocity.y < -0.2 {
                index = max(index - 1, 0)
            }

            let newOffsetY = CGFloat(index) * pageHeight - scrollView.contentInset.top
            targetContentOffset.pointee.y = newOffsetY
        }
    }
}
