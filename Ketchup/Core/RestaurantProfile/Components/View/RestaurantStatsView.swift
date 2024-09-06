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
    @State private var currentDay: String = getCurrentDay()
    @State private var selectedDay: String = getCurrentDay()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                //generalInfoSection
                openingHoursSection
                popularTimesSection
                //websiteLinksSection
                //ratingSection
                additionalInfoSection
                peopleAlsoSearchSection
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private var generalInfoSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "General Information", icon: "info.circle")
                InfoRow(title: "Name", value: restaurant.name, icon: "building")
                InfoRow(title: "Cuisine", value: restaurant.categoryName ?? "N/A", icon: "fork.knife")
                InfoRow(title: "Price", value: restaurant.price ?? "N/A", icon: "dollarsign.circle")
               
            }
        }
    }
    
  

    private var openingHoursSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                // Section header for Opening Hours
                SectionHeader(title: "Opening Hours", icon: "clock")

                // Opening Hours
                if let openingHours = restaurant.openingHours {
                    ForEach(openingHours, id: \.day) { hour in
                        HStack {
                            Text(hour.day ?? "N/A")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                                .frame(width: 100, alignment: .leading)
                            Text(hour.hours ?? "N/A")
                                .font(.custom("MuseoSansRounded-300", size: 16))
                        }
                    }
                } else {
                    Text("No opening hours available")
                        .font(.custom("MuseoSansRounded-300", size: 16))
                }
            }
        }
    }

    private var popularTimesSection: some View {
           VStack(alignment: .leading, spacing: 10) {
               SectionHeader(title: "Popular Times", icon: "clock")
               
               DaySelectionView(selectedDay: $selectedDay)
               
               if let popularTimes = restaurant.popularTimesHistogram {
                   BarChart(data: dataForDay(selectedDay, popularTimes: popularTimes))
                      
               } else {
                   Text("No popular times data available")
                       .font(.custom("MuseoSansRounded-300", size: 14))
                       .foregroundColor(.gray)
               }
           }
           .frame(maxWidth: .infinity)
           .padding()
           .background(Color.secondary.opacity(0.1))
           .cornerRadius(10)
       }
       
       private func dataForDay(_ day: String, popularTimes: PopularTimesHistogram) -> [PopularTimeItem] {
           switch day {
           case "Mon": return popularTimes.mo ?? []
           case "Tue": return popularTimes.tu ?? []
           case "Wed": return popularTimes.we ?? []
           case "Thu": return popularTimes.th ?? []
           case "Fri": return popularTimes.fr ?? []
           case "Sat": return popularTimes.sa ?? []
           case "Sun": return popularTimes.su ?? []
           default: return []
           }
       }
    // Helper function to check for valid popular times data
    private func validPopularTimesData() -> [PopularTimeItem]? {
        let data = dataForDay(currentDay)
        return data.isEmpty ? nil : data
    }
    
    private var ratingSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Ratings & Reviews", icon: "star.fill")
                if let stats = restaurant.stats {
                    HStack {
                        AnimatedCounter(count: stats.postCount, title: "Posts")
                        Spacer()
                        AnimatedCounter(count: stats.collectionCount, title: "Collections")
                    }
                }
                if let reviewTags = restaurant.reviewsTags {
                    ForEach(reviewTags.prefix(5), id: \.title) { tag in
                        HStack {
                            if let title = tag.title {
                                Text(title)
                            }
                            Spacer()
                            if let count = tag.count {
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
    
    private var websiteLinksSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Website Links", icon: "link")
                linkRow(title: "Website", value: restaurant.website, placeholder: "Website link", icon: "globe")
                linkRow(title: "Menu", value: restaurant.menuUrl, placeholder: "Menu link", icon: "list.bullet")
            }
        }
    }
    
    private var additionalInfoSection: some View {
        SectionBox {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Additional Information", icon: "list.bullet")
                if let additionalInfo = restaurant.additionalInfo {
                    Group {
                        infoGroup(title: "Accessibility", icon: "figure.roll", items: additionalInfo.accessibility)
                        infoGroup(title: "Amenities", icon: "wifi", items: additionalInfo.amenities)
                        infoGroup(title: "Atmosphere", icon: "sun.max", items: additionalInfo.atmosphere)
                        infoGroup(title: "Children", icon: "person.2", items: additionalInfo.children)
                        infoGroup(title: "Crowd", icon: "person.3", items: additionalInfo.crowd)
                        infoGroup(title: "Dining Options", icon: "fork.knife", items: additionalInfo.diningOptions)
                        infoGroup(title: "From the Business", icon: "building.2", items: additionalInfo.fromTheBusiness)
                        infoGroup(title: "Highlights", icon: "sparkles", items: additionalInfo.highlights)
                        infoGroup(title: "Offerings", icon: "gift", items: additionalInfo.offerings)
                        infoGroup(title: "Parking", icon: "parkingsign", items: additionalInfo.parking)
                        infoGroup(title: "Payments", icon: "creditcard", items: additionalInfo.payments)
                        infoGroup(title: "Pets", icon: "pawprint", items: additionalInfo.pets)
                        infoGroup(title: "Planning", icon: "calendar", items: additionalInfo.planning)
                        infoGroup(title: "Popular For", icon: "star", items: additionalInfo.popularFor)
                        infoGroup(title: "Service Options", icon: "hand.raised", items: additionalInfo.serviceOptions)
                    }
                } else {
                    Text("No additional information available")
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
                            if let title = item.title {
                                Text(title)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                                    .fontWeight(.medium)
                            }
                        }
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
                        UIApplication.shared.open(URL(string: urlString)!)
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
    
    private func infoGroup(title: String, icon: String, items: [InfoItem]?) -> some View {
        Group {
            if let items = items, !items.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
//                        Image(systemName: icon)
//                            .foregroundColor(.gray)
                        Text(title)
                            .font(.custom("MuseoSansRounded-300", size: 18))
                            .fontWeight(.medium)
                    }
                    ForEach(items, id: \.name) { item in
                        if let value = item.value, let name = item.name {
                            HStack {
                                Image(systemName: value ? "checkmark" : "xmark")
                                    .foregroundColor(value ? .green : .red)
                                Text(name)
                                    .font(.custom("MuseoSansRounded-300", size: 16))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func dataForDay(_ day: String) -> [PopularTimeItem] {
        switch day {
        case "Monday": return restaurant.popularTimesHistogram?.mo ?? []
        case "Tuesday": return restaurant.popularTimesHistogram?.tu ?? []
        case "Wednesday": return restaurant.popularTimesHistogram?.we ?? []
        case "Thursday": return restaurant.popularTimesHistogram?.th ?? []
        case "Friday": return restaurant.popularTimesHistogram?.fr ?? []
        case "Saturday": return restaurant.popularTimesHistogram?.sa ?? []
        case "Sunday": return restaurant.popularTimesHistogram?.su ?? []
        default: return []
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
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
           //.shadow(color: .gray, radius: 2)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
           // Image(systemName: icon)
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
        VStack {
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
struct DaySelectionView: View {
    @Binding var selectedDay: String
    let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        HStack {
            ForEach(days, id: \.self) { day in
                Button(action: {
                    selectedDay = day
                }) {
                    Text(day)
                        .font(.custom("MuseoSansRounded-700", size: 14))
                        .foregroundColor(selectedDay == day ? .black : .gray)
                        .padding(.bottom, 2)
                        .overlay(
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedDay == day ? .black : .clear)
                                .offset(y: 2),
                            alignment: .bottom
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct BarChart: View {
    let data: [PopularTimeItem]
    
    // Heights for components
    private let barChartHeight: CGFloat = 100
    private let labelHeight: CGFloat = 60
    private let spacing: CGFloat = 10 // Spacing between bars and labels
    private let gridLineCount = 4

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                let availableWidth = geometry.size.width
                let barCount = CGFloat(data.count)
                let barWidth = (availableWidth - (barCount - 1) * 2) / barCount
                
                // Bar chart with manually aligned gridlines
                ZStack(alignment: .bottomLeading) {
                    
                    // Manually aligned grid lines
                    VStack(spacing: 0) {
                        // Top aligned (100%)
                        HStack(alignment: .top, spacing: 4) {
                            Text("100%")
                                .font(.custom("MuseoSansRounded-300", size: 8))
                                .foregroundColor(.gray)
                                .frame(width: 25, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        Spacer() // Spacer between top and next grid line

                        // Middle aligned lines
                        ForEach(1..<gridLineCount, id: \.self) { i in
                            HStack(spacing: 4) {
                                Text("\(100 - i * (100 / gridLineCount))%")
                                    .font(.custom("MuseoSansRounded-300", size: 8))
                                    .foregroundColor(.gray)
                                    .frame(width: 25, alignment: .trailing)
                                
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            Spacer()
                        }

                        // Bottom aligned (0%)
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("0%")
                                .font(.custom("MuseoSansRounded-300", size: 8))
                                .foregroundColor(.gray)
                                .frame(width: 25, alignment: .trailing)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                    }
                    .frame(height: barChartHeight)
                    
                    // Bars
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(data, id: \.hour) { item in
                            VStack(spacing: 0) {
                                if let occupancyPercent = item.occupancyPercent {
                                    Rectangle()
                                        .fill(Color("Colors/AccentColor"))
                                        .frame(width: barWidth, height: CGFloat(occupancyPercent) / 100 * barChartHeight)
                                }
                            }
                        }
                    }
                }
                .frame(height: barChartHeight)
                
                // Hour labels aligned with the bars
                HStack(alignment: .top, spacing: 2) {
                    ForEach(data, id: \.hour) { item in
                        if let hour = item.hour {
                            Text(formatHour(hour))
                                .font(.custom("MuseoSansRounded-300", size: 10))
                                .foregroundColor(.gray)
                                .frame(width: barWidth)
                                .fixedSize()
                                .rotationEffect(.degrees(-90), anchor: .topLeading)
                                .offset(y: 5)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    }
                }
                .frame(height: labelHeight)
                .padding(.top, spacing) // Add spacing between chart and labels
            }
        }
        .frame(height: barChartHeight + labelHeight + spacing) // Total height
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date).lowercased()
    }
}
func getCurrentDay() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E"
    return dateFormatter.string(from: Date())
}

func getNextDay(from currentDay: String) -> String {
    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    guard let index = days.firstIndex(of: currentDay) else { return currentDay }
    return days[(index + 1) % 7]
}

func getPreviousDay(from currentDay: String) -> String {
    let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    guard let index = days.firstIndex(of: currentDay) else { return currentDay }
    return days[(index - 1 + 7) % 7]
}
