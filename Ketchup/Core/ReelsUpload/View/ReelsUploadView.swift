//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//
import SwiftUI
import AVKit
import AVFoundation
import InstantSearchSwiftUI
enum Field: Hashable {
        case caption
        
    }
struct ReelsUploadView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var tabBarController: TabBarController
    @State private var isPickingRestaurant = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isVideoExpanded = false
    @State private var isTaggingUsers = false
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    let writtenReview: Bool
    @State private var currentMediaIndex = 0
    private let spacing: CGFloat = 12  // Adjusted spacing
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 4  // Adjusted to make preview smaller
    }
    private var expandedWidth: CGFloat {
        UIScreen.main.bounds.width * 5/6
    }
    @State private var videoPlayers: [Int: VideoPlayerTest] = [:]
    @State private var isPlaying: Bool = false
    @State private var volume: Float = 0.5
    @State private var isShowingGoodForSelection = false
    @State private var showTaggingSheet = false
    @State private var showPointsInfo = false
   // @FocusState private var isCaptionFocused: Bool// Set default to false
    @State private var isKeyboardVisible = false

    init(uploadViewModel: UploadViewModel, cameraViewModel: CameraViewModel, writtenReview: Bool = false) {
        self.uploadViewModel = uploadViewModel
        self.cameraViewModel = cameraViewModel
        self.writtenReview = writtenReview
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Top bar with back button
                    HStack {
                        Button(action: {
                            if !isKeyboardVisible{
                                dismiss()
                            } else {
                                isKeyboardVisible = false
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(Color("Colors/AccentColor"))
                        }
                        .padding([.leading, .top])
                        Spacer()
                    }
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(spacing: spacing) {
                                if !isKeyboardVisible {
                                    if writtenReview {
                                        restaurantSelector
                                        restaurantSelector
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        HStack {
                                            if !isVideoExpanded {
                                                VStack {
                                                    restaurantSelector
                                                }
                                                .frame(maxWidth: .infinity, alignment: .center)
                                            }
                                            VStack {
                                                mixedMediaPreview
                                            }
                                            .frame(maxWidth: .infinity, alignment: .center)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, spacing)
                                    }
                                    
                                }
                                if !isVideoExpanded {
                                    if !isKeyboardVisible {
                                        Divider()
                                    }
                                    captionEditor
                                    if uploadViewModel.isMentioning {
                                        mentionsList
                                    }
                                    if !isKeyboardVisible {
                                        Divider()
                                        tagPhotosButton
                                        Divider()
                                        goodForButton
                                        Divider()
                                        tagUsersButton
                                        Divider()
                                        ratingsSection
                                    }
                                }
                            }
                            .padding(.horizontal, spacing)
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom bar with points and post button
                    if !isKeyboardVisible {
                        HStack {
                            //pointsProgressBar
                            //Spacer()
                            postButton
                        }
                        .padding([.bottom, .horizontal])
                        .padding(.top, 2)
                        .background(Color.white)
                    } else if isKeyboardVisible {
                        HStack{
                            Spacer()
                            Button(action: {
                                dismissKeyboard()
                                //isCaptionFocused = false
                            }) {
                                Text("Done")
                                    .font(.custom("MuseoSansRounded-500", size: 12))
                                    .foregroundColor(Color("Colors/AccentColor"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color("Colors/AccentColor"), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 4)
                        }
                    }
                    
                }
                if showPointsInfo {
                    Color.black.opacity(0.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // Tap outside the box to dismiss
                            showPointsInfo = false
                        }
                    PointsInfoOverlay(uploadViewModel: uploadViewModel)
                        .onTapGesture {
                            showPointsInfo = false
                        }
                    
                }
            }
            .onTapGesture {
                dismissKeyboard()
                if isVideoExpanded {
                    withAnimation(.spring()) {
                        isVideoExpanded = false
                    }
                }
            }
            .sheet(isPresented: $showTaggingSheet) {
                TaggingSheetView(uploadViewModel: uploadViewModel)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .preferredColorScheme(.light)
            .gesture(
                DragGesture().onChanged { value in
                    if value.translation.height > 50 {
                        dismissKeyboard()
                    }
                }
            )
            .onChange(of: uploadViewModel.caption) { _ in
                uploadViewModel.checkForMentioning()
            }
            .navigationDestination(isPresented: $isPickingRestaurant) {
                UploadFlowRestaurantSelector(uploadViewModel: uploadViewModel, cameraViewModel: cameraViewModel, isEditingRestaurant: true)
                    .navigationTitle("Select Restaurant")
            }
            .sheet(isPresented: $isTaggingUsers) {
                NavigationStack {
                    SelectFollowingView(uploadViewModel: uploadViewModel)
                        .navigationTitle("Tag Users")
                }
                .presentationDetents([.height(UIScreen.main.bounds.height * 0.5)])
            }
            .onChange(of: uploadViewModel.caption) { _ in
                if uploadViewModel.filteredMentionedUsers.isEmpty {
                    let text = uploadViewModel.checkForAlgoliaTagging()
                    if !text.isEmpty {
                        searchViewModel.searchQuery = text
                        Debouncer(delay: 0).schedule {
                            searchViewModel.notifyQueryChanged()
                        }
                    }
                }
            }
            .onAppear {
                //isCaptionFocused = false
                setupKeyboardObservers()
                uploadViewModel.fetchFollowingUsers()
            }
            .onDisappear {
                removeKeyboardObservers()
            }
        }
    }

    var pointsProgressBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Points: \(uploadViewModel.currentPoints)/\(uploadViewModel.maxPoints)")
                    .font(.custom("MuseoSansRounded-500", size: 14))
                    .foregroundColor(.black)

                Button(action: {
                    showPointsInfo.toggle()
                }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 4)
            }

            ProgressView(value: Double(uploadViewModel.currentPoints), total: Double(uploadViewModel.maxPoints))
                .progressViewStyle(LinearProgressViewStyle(tint: Color("Colors/AccentColor")))
                .frame(width: 150)
        }
    }

    var goodForButton: some View {
        Button(action: {
            isShowingGoodForSelection = true
        }) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("What's this place good for?")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .foregroundColor(.black)
                }
                Spacer()
                HStack {
                    Text("\(uploadViewModel.goodFor.count)/7 selected")
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .foregroundColor(Color("Colors/AccentColor"))
                    Image(systemName: "chevron.right")
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $isShowingGoodForSelection) {
            GoodForSelectionView(selectedOptions: $uploadViewModel.goodFor)
        }
    }

    var tagPhotosButton: some View {
        VStack{
            Button(action: {
                showTaggingSheet = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What's in your photos?")
                            .font(.custom("MuseoSansRounded-500", size: 16))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    HStack {
                        Text("\(taggedPhotosCount)/\(uploadViewModel.mixedMediaItems.count) tagged")
                            .font(.custom("MuseoSansRounded-500", size: 14))
                            .foregroundColor(Color("Colors/AccentColor"))
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                    }
                }
            }
        }
       
    }
    private var taggedPhotosCount: Int {
        uploadViewModel.mixedMediaItems.filter { $0.description != nil || $0.descriptionCategory != nil }.count
    }
    var tagUsersButton: some View {
        Button {
            isTaggingUsers = true
        } label: {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.gray)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Went with anyone?")
                        .font(.custom("MuseoSansRounded-500", size: 16))
                        .foregroundColor(.black)
                }
                Spacer()
                HStack {
                    Text(uploadViewModel.taggedUsers.count == 1 ? "1 person" : "\(uploadViewModel.taggedUsers.count) people")
                        .font(.custom("MuseoSansRounded-500", size: 14))
                        .foregroundColor(Color("Colors/AccentColor"))
                    Image(systemName: "chevron.right")
                        .foregroundColor(.black)
                }
            }
        }
    }

    var restaurantSelector: some View {
        Button {
            isPickingRestaurant = true
        } label: {
            if uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil {
                VStack {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(Color("Colors/AccentColor"))
                    Text("Add a restaurant")
                        .foregroundColor(.black)
                }
            } else if let restaurant = uploadViewModel.restaurant {
                VStack {
                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .medium)
                    Text(restaurant.name)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                    if let cuisine = restaurant.categoryName, let price = restaurant.price {
                        Text("\(cuisine), \(price)")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.black)
                    } else if let cuisine = restaurant.categoryName {
                        Text(cuisine)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.black)
                    } else if let price = restaurant.price {
                        Text(price)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.black)
                    }
                    if let address = restaurant.address {
                        Text(address)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.black)
                    }
                    if !uploadViewModel.fromRestaurantProfile {
                        Text("Edit")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
            } else if let request = uploadViewModel.restaurantRequest {
                VStack {
                    RestaurantCircularProfileImageView(size: .medium)
                    Text(request.name)
                        .font(.custom("MuseoSansRounded-500", size: 16))
                    Text("\(request.city), \(request.state)")
                        .font(.custom("MuseoSansRounded-300", size: 10))
                    Text("(To be created)")
                        .foregroundStyle(.gray)
                        .font(.custom("MuseoSansRounded-300", size: 10))
                    Text("Edit")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
            }
        }
        .disabled(uploadViewModel.fromRestaurantProfile)
    }

    var mixedMediaPreview: some View {
        VStack(spacing: 8) {
            if !uploadViewModel.mixedMediaItems.isEmpty {
                TabView(selection: $currentMediaIndex) {
                    ForEach(0..<uploadViewModel.mixedMediaItems.count, id: \.self) { index in
                        let item = uploadViewModel.mixedMediaItems[index]
                        Group {
                            if item.type == .photo {
                                if let image = item.localMedia as? UIImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Color.gray  // Placeholder
                                }
                            } else if item.type == .video {
                                VideoPlayerTest(videoURL: item.localMedia as? URL, isVideoExpanded: $isVideoExpanded, isPlaying: $isPlaying, volume: $volume) { player in
                                    videoPlayers[index] = player
                                }
                            }
                        }
                        .frame(width: isVideoExpanded ? expandedWidth : width,
                               height: isVideoExpanded ? expandedWidth * 6/5 : width * 6/5)
                        .cornerRadius(10)
                        .clipped()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(width: isVideoExpanded ? expandedWidth : width,
                       height: isVideoExpanded ? expandedWidth * 6/5 : width * 6/5)

                if uploadViewModel.mixedMediaItems[currentMediaIndex].type == .video {
                    VideoControlButtons(
                        isPlaying: $isPlaying,
                        volume: $volume,
                        onPlayPause: {
                            videoPlayers[currentMediaIndex]?.togglePlayPause()
                        },
                        onVolumeToggle: {
                            videoPlayers[currentMediaIndex]?.toggleVolume()
                        }
                    )
                    .frame(width: isVideoExpanded ? expandedWidth : width)
                }

                if uploadViewModel.mixedMediaItems.count > 1 {
                    Text("\(currentMediaIndex + 1) / \(uploadViewModel.mixedMediaItems.count)")
                        .font(.caption)
                        .padding(.top, 5)
                }
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: width, height: width * 6/5)
                    .cornerRadius(10)
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isVideoExpanded.toggle()
            }
        }
    }

    var captionEditor: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $uploadViewModel.caption)
                    .font(.custom("MuseoSansRounded-300", size: 14))
                    .frame(height: isKeyboardVisible ? 200 : 75)
                    .background(Color.white)
                    .cornerRadius(5)
                   // .focused($isCaptionFocused)
                    .onChange(of: uploadViewModel.caption) { _ in
                        uploadViewModel.checkForMentioning()
                    }
                if uploadViewModel.caption.isEmpty {
                    Text("Enter a caption...")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(Color.gray)
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                }
            }
            HStack {
                Spacer()
                Text("\(uploadViewModel.caption.count)/750")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(.gray)
                
                // Done button to dismiss the keyboard
              
            }
        }
        .onChange(of: uploadViewModel.caption) { _ in
            if uploadViewModel.caption.count >= 7500 {
                uploadViewModel.caption = String(uploadViewModel.caption.prefix(750))
            }
        }
    }

    var mentionsList: some View {
        Group {
            if !uploadViewModel.filteredMentionedUsers.isEmpty {
                ForEach(uploadViewModel.filteredMentionedUsers, id: \.id) { user in
                    Button(action: {
                        let username = user.username
                        var words = uploadViewModel.caption.split(separator: " ").map(String.init)
                        words.removeLast()
                        words.append("@" + username)
                        uploadViewModel.caption = words.joined(separator: " ") + " "
                        uploadViewModel.isMentioning = false
                    }) {
                        HStack {
                            UserCircularProfileImageView(profileImageUrl: user.profileImageUrl, size: .small)
                            Text(user.username)
                                .font(.custom("MuseoSansRounded-300", size: 14))
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .contentShape(Rectangle())
                }
            } else {
                InfiniteList(searchViewModel.userHits, itemView: { hit in
                    Button {
                        let username = hit.object.username
                        var words = uploadViewModel.caption.split(separator: " ").map(String.init)
                        words.removeLast()
                        words.append("@" + username)
                        uploadViewModel.caption = words.joined(separator: " ") + " "
                        uploadViewModel.isMentioning = false
                    } label: {
                        UserCell(user: hit.object)
                            .padding()
                    }
                    Divider()
                }, noResults: {
                    Text("No results found")
                        .foregroundStyle(.black)
                })
            }
        }
    }

    var ratingsSection: some View {
        VStack(spacing: 8) {
            OverallRatingView(rating: calculateOverallRating())
            RatingSliderGroup(label: "Food", rating: $uploadViewModel.foodRating, isNA: $uploadViewModel.isFoodNA)
            RatingSliderGroup(label: "Atmosphere", rating: $uploadViewModel.atmosphereRating, isNA: $uploadViewModel.isAtmosphereNA)
            RatingSliderGroup(label: "Value", rating: $uploadViewModel.valueRating, isNA: $uploadViewModel.isValueNA)
            RatingSliderGroup(label: "Service", rating: $uploadViewModel.serviceRating, isNA: $uploadViewModel.isServiceNA)
        }
    }

    func calculateOverallRating() -> String {
        var totalRating = 0.0
        var count = 0

        if !uploadViewModel.isFoodNA {
            totalRating += uploadViewModel.foodRating
            count += 1
        }
        if !uploadViewModel.isAtmosphereNA {
            totalRating += uploadViewModel.atmosphereRating
            count += 1
        }
        if !uploadViewModel.isValueNA {
            totalRating += uploadViewModel.valueRating
            count += 1
        }
        if !uploadViewModel.isServiceNA {
            totalRating += uploadViewModel.serviceRating
            count += 1
        }

        if count == 0 {
            return "N/A"
        } else {
            return String(format: "%.1f", totalRating / Double(count))
        }
    }

    var postButton: some View {
        Button {
            triggerHapticFeedback()
            if writtenReview {
                uploadViewModel.mediaType = .written
            }
            if uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil {
                alertMessage = "Please select a restaurant."
                showAlert = true
            } else {
                uploadPost()
            }
        } label: {
            Text(uploadViewModel.isLoading ? "Creating Post" : "Post")
                .foregroundColor(.white)
                .font(.custom("MuseoSansRounded-700", size: 16))
                .frame(width: 100, height: 40)
                .background(uploadViewModel.isLoading ? .gray : Color("Colors/AccentColor"))
                .cornerRadius(12)
        }
        .disabled(uploadViewModel.isLoading)
        .opacity((uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) ? 0.5 : 1.0)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Enter Details"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func uploadPost() {
        Task {
            do {
                let overallRating = calculateOverallRating()
                let post = try await uploadViewModel.uploadPost()
                UploadService.shared.newestPost = post
                NotificationCenter.default.post(name: .presentUploadView, object: nil)
                if !uploadViewModel.fromRestaurantProfile {
                    tabBarController.selectedTab = 0
                }
                uploadViewModel.reset()
                cameraViewModel.reset()
                uploadViewModel.dismissAll = true
            } catch {
                alertMessage = "Failed to upload post: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = true
        }
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
            self.isKeyboardVisible = false
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}
func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
struct PointsInfoOverlay: View {
    @ObservedObject var uploadViewModel: UploadViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Earn Points")
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(pointCriteria, id: \.0) { (description, conditionMet) in
                HStack {
                    Image(systemName: conditionMet ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(conditionMet ? .green : .gray)
                    Text(description)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: 300)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var pointCriteria: [(String, Bool)] {
        [
            ("Add a caption to get more points.", !uploadViewModel.caption.isEmpty),
            ("Tag your media to get more points.", uploadViewModel.mixedMediaItems.contains { $0.description != nil || $0.descriptionCategory != nil }),
            ("Tag a user to get more points.", !uploadViewModel.taggedUsers.isEmpty),
            ("Add 'What is this place good for?' to get more points.", !uploadViewModel.goodFor.isEmpty)
        ]
    }
   
}
struct VideoPlayerTest: View {
    let videoURL: URL?
    @State private var player: AVPlayer?
    @Binding var isVideoExpanded: Bool
    @Binding var isPlaying: Bool
    @Binding var volume: Float
    @State private var videoAspectRatio: CGFloat = 16/9  // Default aspect ratio
    var onPlayerCreated: (VideoPlayerTest) -> Void
    
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (20 * 2)) / 3
    }
    
    private var expandedWidth: CGFloat {
        UIScreen.main.bounds.width * 5/6
    }
    
    var body: some View {
        ZStack {
            if let player = player {
                CustomVideoPlayer(player: player,
                                  videoGravity: .resizeAspectFill,
                                  showsPlaybackControls: false)
            }
        }
        .onAppear {
            setupPlayer()
            onPlayerCreated(self)
        }
        .onDisappear {
            deinitPlayer()
        }
        .onChange(of: isVideoExpanded) { newValue in
            if !newValue {
                player?.seek(to: .zero)
                player?.play()
                isPlaying = true
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = videoURL else { return }
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.actionAtItemEnd = .none
        player?.volume = volume
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: playerItem,
                                               queue: .main) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        // Get video aspect ratio
        if let track = playerItem.asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            videoAspectRatio = abs(size.width / size.height)
        }
        
        player?.play()
        isPlaying = true
    }
    
    private func deinitPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    func toggleVolume() {
        volume = volume > 0 ? 0 : 0.5
        player?.volume = volume
    }
}

struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer
    var videoGravity: AVLayerVideoGravity
    var showsPlaybackControls: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsVideoFrameAnalysis = false
        controller.showsPlaybackControls = false
        controller.exitsFullScreenWhenPlaybackEnds = true
        controller.allowsPictureInPicturePlayback = true
        controller.videoGravity = videoGravity
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.showsPlaybackControls = showsPlaybackControls
        uiViewController.videoGravity = videoGravity
    }
}

struct VideoControlButtons: View {
    @Binding var isPlaying: Bool
    @Binding var volume: Float
    var onPlayPause: () -> Void
    var onVolumeToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            Button(action: onVolumeToggle) {
                Image(systemName: volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
struct ProgressButton: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Button background
            RoundedRectangle(cornerRadius: 12)
                .fill(uploadViewModel.isLoading ? .gray : Color("Colors/AccentColor"))
            
            // Progress bar
            Rectangle()
                .fill(Color("Colors/AccentColor"))
                .frame(width: calculateProgressWidth(), height: nil)
            
            // Button text
            Text(uploadViewModel.isLoading ? "Creating Post" : "Post")
                .foregroundColor(.white)
                .font(.custom("MuseoSansRounded-700", size: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 190, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func calculateProgressWidth() -> CGFloat {
        return 190 * CGFloat(uploadViewModel.uploadProgress / 100)
    }
}
