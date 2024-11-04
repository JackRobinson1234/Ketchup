//
//  ZoomableViews.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/28/24.
//

import SwiftUI
import Kingfisher
import AVFoundation
struct ZoomableImage: View {
    let imageURL: String
    
    var body: some View {
        ZoomableScrollView {
            KFImage(URL(string: imageURL))
                .resizable()
                .scaledToFit()
                .cornerRadius(10)
        }
    }
}
struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: self.content))
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = self.content
        assert(context.coordinator.hostingController.view.superview == uiView)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        private var initialZoomScale: CGFloat = 1.0
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            initialZoomScale = scrollView.zoomScale
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale != initialZoomScale {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView.zoomScale != 1.0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }
    }
}
struct ZoomableVideoPlayer: UIViewRepresentable {
    @ObservedObject var videoCoordinator: VideoPlayerCoordinator
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let playerView = VideoPlayerUIView(coordinator: videoCoordinator)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(playerView)
        
        NSLayoutConstraint.activate([
            playerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            playerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            playerView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            playerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])
        
        return scrollView
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableVideoPlayer
        
        init(_ parent: ZoomableVideoPlayer) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            if scale != 1.0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView.zoomScale != 1.0 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollView.setZoomScale(1.0, animated: true)
                }
            }
        }
    }
}

class VideoPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    init(coordinator: VideoPlayerCoordinator) {
        super.init(frame: .zero)
        
        let playerLayer = AVPlayerLayer(player: coordinator.player)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        self.playerLayer = playerLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}
