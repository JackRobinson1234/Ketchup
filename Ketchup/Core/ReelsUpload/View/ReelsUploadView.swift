//
//  ReelsUploadView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/21/24.
//

import SwiftUI
import AVKit
import AVFoundation

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
    
    private let maxCharacters = 25
    private let spacing: CGFloat = 20
    private var width: CGFloat {
        (UIScreen.main.bounds.width - (spacing * 2)) / 3
    }
    
    @Namespace private var animationNamespace
    
    var overallRatingPercentage: Double {
        ((uploadViewModel.foodRating + uploadViewModel.atmosphereRating + uploadViewModel.valueRating + uploadViewModel.serviceRating) / 4) * 10
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    HStack {
                        Spacer()
                        if !isVideoExpanded {
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
                                            .font(.custom("MuseoSansRounded-300", size: 20))
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
                                            .font(.custom("MuseoSansRounded-300", size: 20))
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
                            
                            Spacer()
                        }
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
                        
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    if !isVideoExpanded {
                        Divider()
                        
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
                                Text("\(uploadViewModel.caption.count)/150")
                                    .font(.custom("MuseoSansRounded-300", size: 10))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                            }
                        }
                        .onChange(of: uploadViewModel.caption) {
                            if uploadViewModel.caption.count >= 150 {
                                uploadViewModel.caption = String(uploadViewModel.caption.prefix(150))
                            }
                        }
                        
                        Divider()
                        
                        VStack(spacing: 10) {
                            OverallRatingView(rating: overallRatingPercentage)
                            RatingSliderGroup(label: "Food", rating: $uploadViewModel.foodRating)
                            RatingSliderGroup(label: "Atmosphere", rating: $uploadViewModel.atmosphereRating)
                            RatingSliderGroup(label: "Value", rating: $uploadViewModel.valueRating)
                            RatingSliderGroup(label: "Service", rating: $uploadViewModel.serviceRating)
                        }
                        
                        Divider()
                        
                        Spacer()
                        
                        Button {
                            if (uploadViewModel.restaurant == nil && uploadViewModel.restaurantRequest == nil) {
                                alertMessage = "Please select a restaurant."
                                showAlert = true
                            } else {
                                Task {
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
                }
                .padding()
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
        .navigationDestination(isPresented: $isPickingRestaurant) {
            SelectRestaurantListView(uploadViewModel: uploadViewModel)
                .navigationTitle("Select Restaurant")
        }
        .onAppear {
            UISlider.appearance().setThumbImage(nil, for: .normal)
        }
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

//struct RatingSliderGroup: View {
//    let label: String
//    let isOverall: Bool
//    @Binding var rating: Double
//    
//    var formattedRating: String {
//        String(format: "%.0f", rating)
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            HStack {
//                Text(label)
//                    .font(isOverall ? .custom("MuseoSansRounded-700", size: 16) : .custom("MuseoSansRounded-300", size: 16))
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                HStack(spacing: 2) {
//                    Text(formattedRating)
//                        .frame(width: 40, alignment: .trailing)
//                        .font(.custom("MuseoSansRounded-300", size: 16))
//                        .foregroundColor(.primary)
//                    
//                    Text("%")
//                        .font(.custom("MuseoSansRounded-300", size: 16))
//                        .foregroundColor(.primary)
//                }
//            }
//            
//            Slider(value: $rating, in: 0...100, step: 1)
//        }
//    }
//}
