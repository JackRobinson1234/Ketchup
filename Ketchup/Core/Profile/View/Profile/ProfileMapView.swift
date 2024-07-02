//
//  ProfileMapView.swift
//  Ketchup
//
//  Created by Jack Robinson on 7/2/24.
//

import SwiftUI
import _MapKit_SwiftUI
import Kingfisher

struct ProfileMapView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @StateObject var feedViewModel = FeedViewModel()
    @State var selectedPost: Post?
    var body: some View {
        Map(initialPosition: .automatic) {
            ForEach(viewModel.posts, id: \.self) { post in
                if let geoPoint = post.restaurant.geoPoint {
                    let lat = geoPoint.latitude
                    let long = geoPoint.longitude
                    if post.mediaType != .written {
                        Annotation(post.restaurant.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                            Button{
                                feedViewModel.posts = [post]
                                selectedPost = post
                            } label:
                            { 
                                PostAnnotationView(post: post)
                            }
                        }
                    } else{
                        Annotation(post.restaurant.name, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)) {
                            NavigationLink(destination: RestaurantProfileView(restaurantId: post.id)) {
                                Circle()
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.7) // Adjust the multiplier as needed
        .cornerRadius(10)
        .fullScreenCover(item: $selectedPost) { post in
            NavigationStack {
                SecondaryFeedView(viewModel: feedViewModel, hideFeedOptions: true, titleText: "Posts")
            }
        }
    }
}

//#Preview {
//    ProfileMapView()
//}
struct PostAnnotationView: View {
    let post: Post
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack() {
                // Square background with point
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Thumbnail image
                if let url = URL(string: post.thumbnailUrl) {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                }
            }
            
        }
    }
}

struct SquareWithPoint: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 6
        let pointHeight: CGFloat = 8
        
        // Top left corner
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0), control: CGPoint(x: 0, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: width - cornerRadius, y: 0))
        
        // Top right corner
        path.addQuadCurve(to: CGPoint(x: width, y: cornerRadius), control: CGPoint(x: width, y: 0))
        
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height - cornerRadius - pointHeight))
        
        // Bottom right corner
        path.addQuadCurve(to: CGPoint(x: width - cornerRadius, y: height - pointHeight), control: CGPoint(x: width, y: height - pointHeight))
        
        // Bottom edge with point
        path.addLine(to: CGPoint(x: (width / 2) + 5, y: height - pointHeight))
        path.addLine(to: CGPoint(x: width / 2, y: height))
        path.addLine(to: CGPoint(x: (width / 2) - 5, y: height - pointHeight))
        path.addLine(to: CGPoint(x: cornerRadius, y: height - pointHeight))
        
        // Bottom left corner
        path.addQuadCurve(to: CGPoint(x: 0, y: height - cornerRadius - pointHeight), control: CGPoint(x: 0, y: height - pointHeight))
        
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
        return path
    }
}
