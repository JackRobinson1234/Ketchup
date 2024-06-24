//
//  ClusterCell.swift
//  Foodi
//
//  Created by Jack Robinson on 5/23/24.
//

import SwiftUI
import MapKit

struct ClusterCell: View {
    var cluster: ExampleClusterAnnotation
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color("Colors/AccentColor"), lineWidth: 2)
                )
            Text("\(cluster.count)")
                .foregroundColor(.black)
                .font(.custom("MuseoSansRounded-300", size: 10))
        }
    }
}
#Preview {
    ClusterCell(cluster: ExampleClusterAnnotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), count: 0))
}


struct Cluster: Identifiable, Hashable, Equatable {
    let id = NSUUID().uuidString
    var coordinate: CLLocationCoordinate2D
    var count: Int
    static func == (lhs: Cluster, rhs: Cluster) -> Bool {
           return lhs.id == rhs.id &&
                  lhs.coordinate.latitude == rhs.coordinate.latitude &&
                  lhs.coordinate.longitude == rhs.coordinate.longitude &&
                  lhs.count == rhs.count
       }
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(coordinate.latitude)
            hasher.combine(coordinate.longitude)
            hasher.combine(count)
        }
}
