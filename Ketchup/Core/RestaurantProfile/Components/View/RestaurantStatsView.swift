//
//  RestaurantStatsView.swift
//  Ketchup
//
//  Created by Joe Ciminelli on 7/3/24.
//


import SwiftUI
import SafariServices

struct RestaurantStatsView: View {
    let restaurant: Restaurant
       @State private var activeLink: LinkItem?
       @State private var showErrorAlert = false
       @State private var errorMessage = ""
       
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generalInfoSection
                contactSection
                websiteLinksSection  // Add this line
                ratingSection
                popularTimesSection
                openingHoursSection
                orderBySection
                additionalInfoSection
                categoriesSection
                peopleAlsoSearchSection
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .sheet(item: $activeLink) { link in
            SafariView(url: link.url)
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var generalInfoSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "General Information", icon: "info.circle")
                InfoRow(title: "Name", value: restaurant.name, icon: "building")
                InfoRow(title: "Cuisine", value: restaurant.categoryName ?? "N/A", icon: "fork.knife")
                InfoRow(title: "Price", value: restaurant.price ?? "N/A", icon: "dollarsign.circle")
                InfoRow(title: "Address", value: restaurant.address ?? "N/A", icon: "mappin")
                if let neighborhood = restaurant.neighborhood {
                    InfoRow(title: "Neighborhood", value: neighborhood, icon: "house")
                }
                if let locatedIn = restaurant.locatedIn {
                    InfoRow(title: "Located In", value: locatedIn, icon: "building.2")
                }
            }
        }
    }
    
    private var contactSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Contact Information", icon: "phone")
                InfoRow(title: "Phone", value: restaurant.phone ?? "N/A", icon: "phone")
            }
        }
    }
    private var websiteLinksSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Website Links", icon: "link")
                linkRow(title: "Website", value: restaurant.website, placeholder: "Website link", icon: "globe")
                linkRow(title: "Menu", value: restaurant.menuUrl, placeholder: "Menu link", icon: "list.bullet")
                linkRow(title: "Google Food", value: restaurant.googleFoodUrl, placeholder: "Google Food link", icon: "g.circle")
            }
        }
    }
    
    private var ratingSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Ratings & Reviews", icon: "star.fill")
                if let stats = restaurant.stats{
                    HStack {
                        AnimatedCounter(count: stats.postCount, title: "Posts")
                        Spacer()
                        AnimatedCounter(count: stats.collectionCount, title: "Collections")
                    }
                }
                if let reviewsTags = restaurant.reviewsTags {
                    ForEach(reviewsTags.prefix(5), id: \.title) { tag in
                        HStack {
                            if let title = tag.title{
                                Text(title)
                            }
                            Spacer()
                            if let count = tag.count{
                                Text("\(count)")
                                    .fontWeight(.bold)
                                    .padding(5)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var popularTimesSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Popular Times", icon: "clock")
                if let popularTimes = restaurant.popularTimesHistogram {
                    PopularTimesChart(popularTimes: popularTimes)
                } else {
                    Text("No popular times data available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }
    
    private var openingHoursSection: some View {
            SectionBox {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Opening Hours", icon: "clock")
                    if let openingHours = restaurant.openingHours {
                        ForEach(openingHours, id: \.day) { hour in
                            HStack {
                                if let day = hour.day{
                                    Text(day)
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                        .frame(width: 100, alignment: .leading)
                                }
                                if let hours = hour.hours{
                                    Text(formatOpeningHours(hours))
                                        .font(.custom("MuseoSansRounded-300", size: 16))
                                }
                            }
                        }
                    } else {
                        Text("No opening hours data available")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    }
                }
            }
        }
    private func formatOpeningHours(_ hours: String) -> String {
            let components = hours.components(separatedBy: "–")
            if components.count == 2 {
                let start = formatTimeString(components[0].trimmingCharacters(in: .whitespaces))
                let end = formatTimeString(components[1].trimmingCharacters(in: .whitespaces))
                return "\(start) - \(end)"
            }
            return hours
        }
    private func formatTimeString(_ time: String) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            if let date = formatter.date(from: time) {
                formatter.dateFormat = "h:mm a"
                return formatter.string(from: date)
            }
            
            return time
        }
    
    private var orderBySection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Order Options", icon: "bag")
                if let orderBy = restaurant.orderBy {
                    ForEach(orderBy, id: \.name) { option in
                        if let name = option.name, let orderUrl = option.orderUrl{
                            linkRow(title: name, value: orderUrl, placeholder: "Order now", icon: "cart")
                        }
                    }
                } else {
                    Text("No order options available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }
    
    private var additionalInfoSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Additional Information", icon: "list.bullet")
                if let additionalInfo = restaurant.additionalInfo {
                    Group {
                        infoGroup(title: "Accessibility", items: additionalInfo.accessibility)
                        infoGroup(title: "Amenities", items: additionalInfo.amenities)
                        infoGroup(title: "Atmosphere", items: additionalInfo.atmosphere)
                        infoGroup(title: "Crowd", items: additionalInfo.crowd)
                        infoGroup(title: "Dining Options", items: additionalInfo.diningOptions)
                        infoGroup(title: "Payments", items: additionalInfo.payments)
                        infoGroup(title: "Pets", items: additionalInfo.pets)
                        infoGroup(title: "Popular For", items: additionalInfo.popularFor)
                        infoGroup(title: "Service Options", items: additionalInfo.serviceOptions)
                    }
                } else {
                    Text("No additional information available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Categories", icon: "tag")
                if let categories = restaurant.categories {
                    ForEach(categories, id: \.self) { category in
                        Text(category)
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    }
                } else {
                    Text("No categories available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }
    
    private var peopleAlsoSearchSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "People Also Search", icon: "magnifyingglass")
                if let peopleAlsoSearch = restaurant.peopleAlsoSearch {
                    ForEach(peopleAlsoSearch, id: \.title) { item in
                        VStack(alignment: .leading) {
                            if let title = item.title{
                                Text(title)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.medium)
                            }
//                            Text("Category: \(item.category)")
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                            Text("Reviews: \(item.reviewsCount)")
//                                .font(.custom("MuseoSansRounded-300", size: 14))
//                            Text("Score: \(String(format: "%.1f", item.totalScore))")
//                                .font(.custom("MuseoSansRounded-300", size: 14))
                        }
                        .padding(.bottom, 5)
                    }
                } else {
                    Text("No related searches available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }
    
    private func linkRow(title: String, value: String?, placeholder: String, icon: String) -> some View {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .frame(width: 20, alignment: .center)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("MuseoSansRounded-300", size: 16))
                        .fontWeight(.medium)
                    if let urlString = value {
                        Button(action: {
                            openURL(urlString, title: title)
                        }) {
                            Text(placeholder)
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .foregroundColor(.blue)
                                .underline()
                        }
                    } else {
                        Text("N/A")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    }
                }
            }
        }
    private func openURL(_ urlString: String, title: String) {
            guard let url = URL(string: urlString) else {
                errorMessage = "Invalid URL"
                showErrorAlert = true
                return
            }
            
            if UIApplication.shared.canOpenURL(url) {
                activeLink = LinkItem(id: title, url: url)
            } else {
                errorMessage = "Unable to open URL"
                showErrorAlert = true
            }
        }
    private func infoGroup(title: String, items: [InfoItem]?) -> some View {
        Group {
            if let items = items, !items.isEmpty {
                Text(title)
                    .font(.custom("MuseoSansRounded-300", size: 18))
                    .fontWeight(.medium)
                ForEach(items, id: \.name) { item in
                    if item.value {
                        Text("✓ \(item.name)")
                            .font(.custom("MuseoSansRounded-300", size: 16))
                    }
                }
            }
        }
    }
}


struct SectionBox<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(.custom("MuseoSansRounded-300", size: 20))
                .fontWeight(.bold)
        }
        .padding(.vertical, 5)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 20, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom("MuseoSansRounded-300", size: 16))
                    .fontWeight(.medium)
                Text(value)
                    .font(.custom("MuseoSansRounded-300", size: 16))
            }
        }
    }
}

struct AnimatedCounter: View {
    let count: Int
    let title: String
    @State private var animatedCount: Int = 0
    
    var body: some View {
        VStack() {
            Text("\(animatedCount)")
                .font(.custom("MuseoSansRounded-300", size: 24))
                .fontWeight(.bold)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        animatedCount = count
                    }
                }
            Text(title)
                .font(.custom("MuseoSansRounded-300", size: 14))
        }
    }
}

struct PopularTimesChart: View {
    let popularTimes: PopularTimesHistogram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                HStack {
                    Text(day)
                        .font(.custom("MuseoSansRounded-300", size: 14))
                        .frame(width: 100, alignment: .leading)
                    BarChart(data: dataForDay(day))
                }
            }
        }
    }
    
    private func dataForDay(_ day: String) -> [PopularTimeItem] {
        
        switch day {
        case "Monday": return popularTimes.mo ?? []
        case "Tuesday": return popularTimes.tu ?? []
        case "Wednesday": return popularTimes.we ?? []
        case "Thursday": return popularTimes.th ?? []
        case "Friday": return popularTimes.fr ?? []
        case "Saturday": return popularTimes.sa ?? []
        case "Sunday": return popularTimes.su ?? []
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
                    if let occupancyPercent = item.occupancyPercent{
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 5, height: CGFloat(occupancyPercent))
                    }
                    if let hour = item.hour {
                        Text("\(hour)")
                            .font(.custom("MuseoSansRounded-300", size: 8))
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {}
}
struct LinkItem: Identifiable {
    let id: String
    let url: URL
}
//#Preview {
//    RestaurantStatsView(restaurant: DeveloperPreview.restaurants[0])
//}
