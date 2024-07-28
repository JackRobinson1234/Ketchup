//
//  ZoomableViews.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/28/24.
//

import SwiftUI
struct ZoomableImage: View {
    let imageURL: String
    
    var body: some View {
        ZoomableScrollView {
            KFImage(URL(string: imageURL))
                .resizable()
                .scaledToFit()
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
struct ZoomableVideoPlayer: View {
    @ObservedObject var videoCoordinator: VideoPlayerCoordinator
    
    var body: some View {
        ZoomableScrollView {
            VideoPlayerView(coordinator: videoCoordinator, videoGravity: .resizeAspectFill)
        }
    }
}
