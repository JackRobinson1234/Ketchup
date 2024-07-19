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

struct ReelsUploadView: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @EnvironmentObject var tabBarController: TabBarController
    @FocusState private var isCaptionEditorFocused: Bool
    @State private var isEditingCaption = false
    @State private var isPickingRestaurant = false
    @State private var titleText: String = ""
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isVideoExpanded = false
    @State private var isTaggingUsers = false
    @StateObject var searchViewModel = SearchViewModel(initialSearchConfig: .users)
    let writtenReview: Bool
    
    private let maxCharacters = 25
    private let spacing: CGFloat = 20
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    
    @Namespace private var animationNamespace
    
    var overallRatingPercentage: Double {
        ((uploadViewModel.foodRating + uploadViewModel.atmosphereRating + uploadViewModel.valueRating + uploadViewModel.serviceRating) / 4)
    }
    
    init(uploadViewModel: UploadViewModel, cameraViewModel: CameraViewModel, writtenReview: Bool = false) {
        self.uploadViewModel = uploadViewModel
        self.cameraViewModel = cameraViewModel
        self.writtenReview = writtenReview
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Spacer().frame(height: 20)  // Top padding
                    
                    if writtenReview {
                        restaurantSelector
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        HStack {
                            Spacer()
                            if !isVideoExpanded {
                                restaurantSelector
                            }
                            if !writtenReview {
                                mediaPreview
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    
                    if !isVideoExpanded {
                        Divider()
                        
                        captionEditor
                        if uploadViewModel.isMentioning {
                            if !uploadViewModel.filteredMentionedUsers.isEmpty{
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
                                    Button{
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
                                        .foregroundStyle(.primary)
                                })
                            }
                        }
                        
                        Divider()
                        
                        ratingsSection
                        
                        Divider()
                        
                        tagUsersButton
                        
                        Divider()
                        
                        postButton
                    }
                }
                .padding()
            }
            .if(writtenReview) { view in
                view.safeAreaPadding(.vertical, 100)
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
        .onChange(of: uploadViewModel.caption) {
            uploadViewModel.checkForMentioning()
        }
        .navigationDestination(isPresented: $isPickingRestaurant) {
            SelectRestaurantListView(uploadViewModel: uploadViewModel)
                .navigationTitle("Select Restaurant")
        }
        .navigationDestination(isPresented: $isTaggingUsers) {
            SelectFollowingView(uploadViewModel: uploadViewModel)
                .navigationTitle("Tag Users")
        }
        .onChange(of: uploadViewModel.caption){
            if uploadViewModel.filteredMentionedUsers.isEmpty{
                print("Entering 1")
                let text = uploadViewModel.checkForAlgoliaTagging()
                if !text.isEmpty{
                    print("Entering 2")
                    searchViewModel.searchQuery = text
                    print(text)
                    Debouncer(delay: 1.0).schedule{
                        print("Entering 3")
                        searchViewModel.notifyQueryChanged()
                    }
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
                        .font(.largeTitle)
                        .foregroundColor(Color("Colors/AccentColor"))
                    Text("Add a restaurant")
                        .foregroundColor(.primary)
                }
            } else if let restaurant = uploadViewModel.restaurant {
                VStack {
                    RestaurantCircularProfileImageView(imageUrl: restaurant.profileImageUrl, size: .xLarge)
                    Text(restaurant.name)
                        .font(.custom("MuseoSansRounded-500", size: 20))
                    if let cuisine = restaurant.categoryName, let price = restaurant.price {
                        Text("\(cuisine), \(price)")
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.primary)
                    } else if let cuisine = restaurant.categoryName {
                        Text(cuisine)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.primary)
                    } else if let price = restaurant.price {
                        Text(price)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.primary)
                    }
                    if let address = restaurant.address {
                        Text(address)
                            .font(.custom("MuseoSansRounded-300", size: 10))
                            .foregroundStyle(.primary)
                    }
                    Text("Edit")
                        .foregroundStyle(Color("Colors/AccentColor"))
                        .font(.custom("MuseoSansRounded-300", size: 10))
                }
            } else if let request = uploadViewModel.restaurantRequest {
                VStack {
                    RestaurantCircularProfileImageView(size: .xLarge)
                    Text(request.name)
                        .font(.custom("MuseoSansRounded-500", size: 20))
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
    }
    
    var mediaPreview: some View {
        Group {
            if uploadViewModel.mediaType == .video {
                VideoPlayerTest(uploadViewModel: uploadViewModel, isVideoExpanded: $isVideoExpanded)
            } else if uploadViewModel.mediaType == .photo {
                FinalPhotoPreview(uploadViewModel: uploadViewModel)
                    .frame(width: isVideoExpanded ? UIScreen.main.bounds.width * 5/6 : width, height: isVideoExpanded ? UIScreen.main.bounds.width * 5/6 : width * (6/5))
                    .cornerRadius(10)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isVideoExpanded.toggle()
                        }
                    }
            } else {
                Rectangle()
                    .frame(width: width, height: 150)
                    .cornerRadius(5)
                    .foregroundStyle(.primary)
            }
        }
    }
    
    var captionEditor: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $uploadViewModel.caption)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .frame(height: 75)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(5)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                dismissKeyboard()
                            }
                        }
                    }
                    .onChange(of: uploadViewModel.caption) {
                        uploadViewModel.checkForMentioning()
                    }
                if uploadViewModel.caption.isEmpty {
                    Text("Enter a caption...")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .foregroundColor(Color.gray)
                        .padding(.horizontal, 25)
                        .padding(.top, 8)
                }
            }
            HStack {
                Spacer()
                Text("\(uploadViewModel.caption.count)/500")
                    .font(.custom("MuseoSansRounded-300", size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
            }
        }
        .onChange(of: uploadViewModel.caption) {
            if uploadViewModel.caption.count >= 500 {
                uploadViewModel.caption = String(uploadViewModel.caption.prefix(500))
            }
        }
    }
    
    var ratingsSection: some View {
        VStack(spacing: 10) {
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
    
    var tagUsersButton: some View {
        Button {
            isTaggingUsers = true
        } label: {
            HStack {
                Text("Went with anyone?")
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .foregroundColor(.black)
                    .frame(alignment: .trailing)
                
                Spacer()
                if uploadViewModel.taggedUsers.isEmpty {
                    Image(systemName: "chevron.right")
                        .frame(width: 25, height: 25)
                        .foregroundColor(Color("Colors/AccentColor"))
                        .padding(.trailing, 10)
                } else {
                    HStack {
                        Text("\(uploadViewModel.taggedUsers.count) people")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                            .foregroundColor(.black)
                        
                        Image(systemName: "chevron.right")
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color("Colors/AccentColor"))
                    }
                    .padding(.trailing, 10)
                }
            }
        }
    }
    
    var postButton: some View {
        Button {
            if writtenReview {
                uploadViewModel.mediaType = .written
            }
            if (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) {
                alertMessage = "Please select a restaurant."
                showAlert = true
            } else {
                Task {
                    let overallRating = calculateOverallRating()
                    await uploadViewModel.uploadPost()
                    uploadViewModel.reset()
                    cameraViewModel.reset()
                    tabBarController.selectedTab = 0
                }
            }
        } label: {
            Text(uploadViewModel.isLoading ? "" : "Post")
                .modifier(StandardButtonModifier(width: 90))
                .overlay {
                    if uploadViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
        }
        .disabled(uploadViewModel.isLoading)
        .opacity((uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) ? 0.5 : 1.0)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Enter Details"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
struct VideoPlayerTest: View {
    @ObservedObject var uploadViewModel: UploadViewModel
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var volume: Float = 0.5
    @Binding var isVideoExpanded: Bool
    
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (20 * 2)) / 3
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            if let player = player {
                CustomVideoPlayer(player: player,
                                  videoGravity: .resizeAspectFill,
                                  showsPlaybackControls: false)
                .frame(width: isVideoExpanded ? UIScreen.main.bounds.width * 5/6 : width,
                       height: isVideoExpanded ? UIScreen.main.bounds.width : width * (6/5))
                .cornerRadius(10)
                .onTapGesture {
                    withAnimation(.spring()) {
                        isVideoExpanded.toggle()
                    }
                }
            }
            
            if !isVideoExpanded {
                VStack(spacing: 20) {
                    Button(action: {
                        isPlaying.toggle()
                        if isPlaying {
                            player?.play()
                        } else {
                            player?.pause()
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause" : "play")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.gray))
                    }
                    
                    Button(action: {
                        volume = volume > 0 ? 0 : 0.5
                        player?.volume = volume
                    }) {
                        Image(systemName: volume > 0 ? "speaker.wave.2" : "speaker.slash")
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.gray))
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            deinitPlayer()
        }
        .onChange(of: isVideoExpanded) { oldValue, newValue in
            if !newValue {
                player?.seek(to: .zero)
                player?.play()
                isPlaying = true
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = uploadViewModel.videoURL else { return }
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
        
        player?.play()
        isPlaying = true
    }
    
    private func deinitPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
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
