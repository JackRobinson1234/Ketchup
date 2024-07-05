//
//  RestaurantStatsView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/3/24.
//

import SwiftUI

struct RestaurantStatsView: View {
    let restaurant: Restaurant
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generalInfoSection
                ratingSection
                popularTimesSection
                additionalInfoSection
            }
            .padding()
        }
    }
    
    private var generalInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "General Information")
            InfoRow(title: "Cuisine", value: restaurant.cuisine ?? "N/A")
            InfoRow(title: "Price", value: restaurant.price ?? "N/A")
            InfoRow(title: "Address", value: restaurant.address ?? "N/A")
            InfoRow(title: "Phone", value: restaurant.phone ?? "N/A")
            if let website = restaurant.website {
                Link("Website", destination: URL(string: website)!)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ratings & Reviews")
            HStack {
                Text("Posts: \(restaurant.stats.postCount)")
                Spacer()
                Text("Collections: \(restaurant.stats.collectionCount)")
            }
            if let reviewsTags = restaurant.reviewsTags {
                ForEach(reviewsTags.prefix(5), id: \.title) { tag in
                    HStack {
                        Text(tag.title)
                        Spacer()
                        Text("\(tag.count)")
                    }
                }
            }
        }
    }
    
    private var popularTimesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Popular Times")
            if let popularTimes = restaurant.popularTimesHistogram {
                PopularTimesChart(popularTimes: popularTimes)
            } else {
                Text("No popular times data available")
            }
        }
    }
    
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Additional Information")
            if let additionalInfo = restaurant.additionalInfo {
                ForEach(additionalInfo.highlights ?? [], id: \.name) { highlight in
                    if highlight.value {
                        Text("✓ \(highlight.name)")
                    }
                }
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.vertical, 5)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
        }
    }
}

struct PopularTimesChart: View {
    let popularTimes: PopularTimesHistogram
    
    var body: some View {
        VStack {
            ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                HStack {
                    Text(day).frame(width: 100, alignment: .leading)
                    BarChart(data: dataForDay(day))
                }
            }
        }
    }
    
    private func dataForDay(_ day: String) -> [PopularTimeItem] {
        switch day {
        case "Monday": return popularTimes.mo
        case "Tuesday": return popularTimes.tu
        case "Wednesday": return popularTimes.we
        case "Thursday": return popularTimes.th
        case "Friday": return popularTimes.fr
        case "Saturday": return popularTimes.sa
        case "Sunday": return popularTimes.su
        default: return []
        }
    }
}

struct BarChart: View {
    let data: [PopularTimeItem]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(data, id: \.hour) { item in
                VStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 5, height: CGFloat(item.occupancyPercent))
                    Text("\(item.hour)")
                        .font(.system(size: 8))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}
