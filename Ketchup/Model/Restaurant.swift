import Foundation
import Firebase
import MapKit
import CoreLocation
import FirebaseFirestore

struct Restaurant: Identifiable, Codable, Hashable {
    let id: String
    let cuisine: String?
    let price: String?
    let name: String
    var geoPoint: GeoPoint?
    let geoHash: String?
    let address: String?
    let city: String?
    let state: String?
    var imageURLs: [String]?
    var profileImageUrl: String?
    var bio: String?
    let _geoloc: geoLoc?
    var stats: RestaurantStats
    
    // New fields
    let additionalInfo: AdditionalInfo?
    let categories: [String]?
    let cid: Int?
    let containsMenuImage: Bool?
    let countryCode: String?
    let googleFoodUrl: String?
    let locatedIn: String?
    let menuUrl: String?
    let neighborhood: String?
    let openingHours: [OpeningHour]?
    let orderBy: [OrderBy]?
    let parentPlaceUrl: String?
    let peopleAlsoSearch: [PeopleAlsoSearch]?
    let permanentlyClosed: Bool?
    let phone: String?
    let plusCode: String?
    let popularTimesHistogram: PopularTimesHistogram?
    let postalCode: Int?
    let reviewsTags: [ReviewTag]?
    let scrapedAt: String?
    let street: String?
    let subCategories: [String]?
    let temporarilyClosed: Bool?
    let updatesFromCustomers: String?
    let url: String?
    let website: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        self.price = try container.decodeIfPresent(String.self, forKey: .price)
        self.name = try container.decode(String.self, forKey: .name)
        self.geoPoint = try container.decodeIfPresent(GeoPoint.self, forKey: .geoPoint)
        self.geoHash = try container.decodeIfPresent(String.self, forKey: .geoHash)
        self.address = try container.decodeIfPresent(String.self, forKey: .address)
        self.city = try container.decodeIfPresent(String.self, forKey: .city)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.imageURLs = try container.decodeIfPresent([String].self, forKey: .imageURLs)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self._geoloc = try container.decodeIfPresent(geoLoc.self, forKey: ._geoloc)
        self.stats = try container.decode(RestaurantStats.self, forKey: .stats)
        
        // Decoding new fields
        self.additionalInfo = try container.decodeIfPresent(AdditionalInfo.self, forKey: .additionalInfo)
        self.categories = try container.decodeIfPresent([String].self, forKey: .categories)
        self.cid = try container.decodeIfPresent(Int.self, forKey: .cid)
        self.containsMenuImage = try container.decodeIfPresent(Bool.self, forKey: .containsMenuImage)
        self.countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        self.googleFoodUrl = try container.decodeIfPresent(String.self, forKey: .googleFoodUrl)
        self.locatedIn = try container.decodeIfPresent(String.self, forKey: .locatedIn)
        self.menuUrl = try container.decodeIfPresent(String.self, forKey: .menuUrl)
        self.neighborhood = try container.decodeIfPresent(String.self, forKey: .neighborhood)
        self.openingHours = try container.decodeIfPresent([OpeningHour].self, forKey: .openingHours)
        self.orderBy = try container.decodeIfPresent([OrderBy].self, forKey: .orderBy)
        self.parentPlaceUrl = try container.decodeIfPresent(String.self, forKey: .parentPlaceUrl)
        self.peopleAlsoSearch = try container.decodeIfPresent([PeopleAlsoSearch].self, forKey: .peopleAlsoSearch)
        self.permanentlyClosed = try container.decodeIfPresent(Bool.self, forKey: .permanentlyClosed)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.plusCode = try container.decodeIfPresent(String.self, forKey: .plusCode)
        do {
            self.popularTimesHistogram = try container.decodeIfPresent(PopularTimesHistogram.self, forKey: .popularTimesHistogram)
        } catch {
            print("Warning: Unable to decode popularTimesHistogram. Error: \(error)")
            self.popularTimesHistogram = nil
        }
        self.postalCode = try container.decodeIfPresent(Int.self, forKey: .postalCode)
        self.reviewsTags = try container.decodeIfPresent([ReviewTag].self, forKey: .reviewsTags)
        self.scrapedAt = try container.decodeIfPresent(String.self, forKey: .scrapedAt)
        self.street = try container.decodeIfPresent(String.self, forKey: .street)
        self.subCategories = try container.decodeIfPresent([String].self, forKey: .subCategories)
        self.temporarilyClosed = try container.decodeIfPresent(Bool.self, forKey: .temporarilyClosed)
        self.updatesFromCustomers = try container.decodeIfPresent(String.self, forKey: .updatesFromCustomers)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.website = try container.decodeIfPresent(String.self, forKey: .website)
    }
    
    init(id: String, cuisine: String? = nil, price: String? = nil, name: String, geoPoint: GeoPoint? = nil, geoHash: String? = nil, address: String? = nil, city: String? = nil, state: String? = nil, imageURLs: [String]? = nil, profileImageUrl: String? = nil, bio: String? = nil, _geoloc: geoLoc? = nil, stats: RestaurantStats, additionalInfo: AdditionalInfo? = nil, categories: [String]? = nil, cid: Int? = nil, containsMenuImage: Bool? = nil, countryCode: String? = nil, googleFoodUrl: String? = nil, locatedIn: String? = nil, menuUrl: String? = nil, neighborhood: String? = nil, openingHours: [OpeningHour]? = nil, orderBy: [OrderBy]? = nil, parentPlaceUrl: String? = nil, peopleAlsoSearch: [PeopleAlsoSearch]? = nil, permanentlyClosed: Bool? = nil, phone: String? = nil, plusCode: String? = nil, popularTimesHistogram: PopularTimesHistogram? = nil, postalCode: Int? = nil, reviewsTags: [ReviewTag]? = nil, scrapedAt: String? = nil, street: String? = nil, subCategories: [String]? = nil, temporarilyClosed: Bool? = nil, updatesFromCustomers: String? = nil, url: String? = nil, website: String? = nil) {
        self.id = id
        self.cuisine = cuisine
        self.price = price
        self.name = name
        self.geoPoint = geoPoint
        self.geoHash = geoHash
        self.address = address
        self.city = city
        self.state = state
        self.imageURLs = imageURLs
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self._geoloc = _geoloc
        self.stats = stats
        self.additionalInfo = additionalInfo
        self.categories = categories
        self.cid = cid
        self.containsMenuImage = containsMenuImage
        self.countryCode = countryCode
        self.googleFoodUrl = googleFoodUrl
        self.locatedIn = locatedIn
        self.menuUrl = menuUrl
        self.neighborhood = neighborhood
        self.openingHours = openingHours
        self.orderBy = orderBy
        self.parentPlaceUrl = parentPlaceUrl
        self.peopleAlsoSearch = peopleAlsoSearch
        self.permanentlyClosed = permanentlyClosed
        self.phone = phone
        self.plusCode = plusCode
        self.popularTimesHistogram = popularTimesHistogram
        self.postalCode = postalCode
        self.reviewsTags = reviewsTags
        self.scrapedAt = scrapedAt
        self.street = street
        self.subCategories = subCategories
        self.temporarilyClosed = temporarilyClosed
        self.updatesFromCustomers = updatesFromCustomers
        self.url = url
        self.website = website
    }
    
    var coordinates: CLLocationCoordinate2D? {
        if let point = self.geoPoint {
            return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        } else {
            return nil
        }
    }
}

struct geoLoc: Codable, Hashable {
    let lat: Double
    let lng: Double
}

struct RestaurantStats: Codable, Hashable {
    var postCount: Int
    var collectionCount: Int
}

struct AdditionalInfo: Codable, Hashable {
    let accessibility: [AccessibilityItem]?
    let amenities: [AmenityItem]?
    let atmosphere: [AtmosphereItem]?
    let children: [ChildrenItem]?
    let crowd: [CrowdItem]?
    let diningOptions: [DiningOptionItem]?
    let highlights: [HighlightItem]?
    let offerings: [OfferingItem]?
    let payments: [PaymentItem]?
    let planning: [PlanningItem]?
    let popularFor: [PopularForItem]?
    let serviceOptions: [ServiceOptionItem]?
}

struct AccessibilityItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct AmenityItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct AtmosphereItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct ChildrenItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct CrowdItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct DiningOptionItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct HighlightItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct OfferingItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct PaymentItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct PlanningItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct PopularForItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct ServiceOptionItem: Codable, Hashable {
    let name: String
    let value: Bool
}

struct OpeningHour: Codable, Hashable {
    let day: String
    let hours: String
}

struct OrderBy: Codable, Hashable {
    let name: String
    let orderUrl: String
    let url: String
}

struct PeopleAlsoSearch: Codable, Hashable {
    let category: String
    let reviewsCount: Int
    let title: String
    let totalScore: Double
}

struct PopularTimesHistogram: Codable, Hashable {
    let mo: [PopularTimeItem]
    let tu: [PopularTimeItem]
    let we: [PopularTimeItem]
    let th: [PopularTimeItem]
    let fr: [PopularTimeItem]
    let sa: [PopularTimeItem]
    let su: [PopularTimeItem]
}

struct PopularTimeItem: Codable, Hashable {
    let hour: Int
    let occupancyPercent: Int
}

struct ReviewTag: Codable, Hashable {
    let count: Int
    let title: String
}
