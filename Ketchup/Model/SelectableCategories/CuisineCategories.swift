//
//  Cuisine Options.swift
//  Foodi
//
//  Created by Jack Robinson on 4/2/24.
//

import Foundation
let cuisineCategories = [
    "Afghan restaurant", "African restaurant", "Alsace restaurant", "American restaurant", "Argentinian restaurant", "Armenian restaurant", "Asian fusion restaurant", "Asian restaurant", "Asturian restaurant", "Australian restaurant", "Authentic Japanese restaurant", "Açaí shop", "Bagel shop", "Bakery", "Bangladeshi restaurant", "Bar", "Bar & grill", "Barbecue restaurant", "Basque restaurant", "Beer garden", "Beer hall", "Belgian restaurant", "Bistro", "Brazilian restaurant", "Breakfast restaurant", "Brewery", "Brewpub", "British restaurant", "Brunch restaurant", "Bubble tea store", "Buffet restaurant", "Burmese restaurant", "Burrito restaurant", "Butcher shop", "Cafe", "Cafeteria", "Cajun restaurant", "Cake shop", "Californian restaurant", "Cambodian restaurant", "Canadian restaurant", "Cantonese restaurant", "Caribbean restaurant", "Catering food and drink supplier", "Central American restaurant", "Cha chaan teng (Hong Kong-style cafe)", "Cheesesteak restaurant", "Chettinad restaurant", "Chicken restaurant", "Chicken shop", "Chicken wings restaurant", "Chilean restaurant", "Chinese Takeaway", "Chinese bakery", "Chinese noodle restaurant", "Chinese restaurant", "Chinese supermarket", "Chinese takeaway", "Chocolate cafe", "Chocolate shop", "Chophouse restaurant", "Churreria", "Cider bar", "Cocktail bar", "Coffee shop", "Colombian restaurant", "Contemporary Louisiana restaurant", "Continental restaurant", "Conveyor belt sushi restaurant", "Costa Rican restaurant", "Creole restaurant", "Creperie", "Cuban restaurant", "Cupcake shop", "Dart bar", "Deli", "Delivery Chinese restaurant", "Delivery Restaurant", "Dessert restaurant", "Dessert shop", "Dim Sum restaurant", "Dim sum restaurant", "Diner", "Dinner theater", "Dominican restaurant", "Doner kebab restaurant", "Donut shop", "Doughnut Shop", "Dumpling restaurant", "East African restaurant", "Eclectic restaurant", "Ecuadorian restaurant", "Egyptian restaurant", "Espresso bar", "Ethiopian restaurant", "European restaurant", "Falafel restaurant", "Family restaurant", "Farmers' market", "Fast food restaurant", "Filipino restaurant", "Fine dining restaurant", "Fish & chips restaurant", "Fondue restaurant", "Food court", "French restaurant", "Fried chicken restaurant", "Frozen yogurt shop", "Fusion restaurant", "Gastropub", "Georgian restaurant", "German restaurant", "Gluten-free restaurant", "Greek restaurant", "Grill", "Guatemalan restaurant", "Halal restaurant", "Hawaiian restaurant", "Health food restaurant", "Hibachi restaurant", "Himalayan/Nepalese restaurant", "Honduran restaurant", "Hong Kong restaurant", "Hot pot restaurant", "Hungarian restaurant", "Ice cream shop", "Ice cream sundae shop", "Indian restaurant", "Indian takeaway", "Indonesian restaurant", "International restaurant", "Irish restaurant", "Israeli restaurant", "Italian restaurant", "Izakaya restaurant", "Jamaican restaurant", "Japanese curry restaurant", "Japanese restaurant", "Japanese steakhouse", "Japanese sweets restaurant", "Jewish restaurant", "Juice bar", "Kabob restaurant", "Kaiseki restaurant", "Kebab shop", "Korean barbecue restaurant", "Korean chicken restaurant", "Korean restaurant", "Kosher restaurant", "Kurdish restaurant", "Laotian restaurant", "Latin American restaurant", "Lebanese restaurant", "Libyan restaurant", "Live music bar", "Lounge", "Lunch restaurant", "Macanese restaurant", "Malaysian restaurant", "Maltese restaurant", "Market", "Martini bar", "Mediterranean restaurant", "Mexican restaurant", "Middle Eastern restaurant", "Moroccan restaurant", "Noodle shop", "North African restaurant", "Northern Italian restaurant", "Pakistani restaurant", "Pan-Latin restaurant", "Parsi restaurant", "Pasta shop", "Persian restaurant", "Peruvian restaurant", "Pho restaurant", "Piano bar", "Pie shop", "Pizza Takeout", "Pizza delivery", "Pizza restaurant", "Poke bar", "Polish restaurant", "Polynesian restaurant", "Portuguese restaurant", "Pozole restaurant", "Po’ boys restaurant", "Pretzel Shop", "Pretzel store", "Pub", "Puerto Rican restaurant", "Punjabi restaurant", "Raclette restaurant", "Ramen restaurant", "Raw food restaurant", "Restaurant", "Restaurant or cafe", "Rice restaurant", "Romanian restaurant", "Russian restaurant", "Salad shop", "Salvadoran restaurant", "Sandwich shop", "Seafood donburi restaurant", "Seafood restaurant", "Self service restaurant", "Shabu-shabu Restaurant", "Shabu-shabu restaurant", "Shandong restaurant", "Shanghainese restaurant", "Shawarma restaurant", "Sichuan restaurant", "Singaporean restaurant", "Snack bar", "Soondae restaurant", "Soul food restaurant", "Soup restaurant", "Soup shop", "South African restaurant", "South American restaurant", "South Indian restaurant", "South Western restaurant (US)", "Southeast Asian restaurant", "Southern Italian restaurant", "Southern restaurant (US)", "Southwestern restaurant (US)", "Spanish restaurant", "Sports bar", "Sri Lankan restaurant", "Stand bar", "Steak house", "Steamed bun shop", "Sukiyaki and Shabu Shabu restaurant", "Sushi restaurant", "Sushi takeaway", "Swedish restaurant", "Swiss restaurant", "Syrian restaurant", "Tacaca restaurant", "Taco restaurant", "Taiwanese restaurant", "Takeaway", "Takeout Restaurant", "Takoyaki restaurant", "Tamale shop", "Tapas bar", "Tapas restaurant", "Tea house", "Tea room", "Teppanyaki restaurant", "Tex-Mex restaurant", "Thai restaurant", "Tiki bar", "Tofu restaurant", "Tofu shop", "Tonkatsu restaurant", "Traditional American restaurant", "Traditional restaurant", "Travel lounge", "Tunisian restaurant", "Turkish restaurant", "Tuscan restaurant", "Udon noodle restaurant", "Ukrainian restaurant", "Uyghur cuisine restaurant", "Uzbeki restaurant", "Vegan restaurant", "Vegetarian cafe and deli", "Vegetarian restaurant", "Venezuelan restaurant", "Vietnamese restaurant", "Welsh restaurant", "West African restaurant", "Western restaurant", "Wine bar", "Winery", "Wok restaurant", "Yakiniku restaurant", "Yakitori restaurant", "Yemeni restaurant", "Yucatan restaurant"
]


let cuisineGroupKeys = [
    "Asian",
    "European",
    "American",
    "Latin American",
    "Middle Eastern",
    "African",
    "Fast Food",
    "Cafes and Bakeries",
    "Bars and Pubs",
    "Seafood",
    "Vegetarian and Vegan",
    "Barbecue and Grill",
    "Fusion and International",
    "Street Food and Food Trucks",
    "Specialty and Dietary",
    "Breakfast and Brunch",
    "Noodles and Pasta",
    "Soup and Hotpot",
    "Sandwich and Deli",
    "Desserts and Sweets",
    "Buffet and All-You-Can-Eat",
    "Family and Casual Dining",
    "Markets and Shops"
]

enum MealTime: String {
    case breakfast
    case lunch
    case dinner
    case dessert
}
let mealTimeCuisineMap: [MealTime: [String]] = [
    .breakfast: [
        "Cafes and Bakeries",
        "Breakfast and Brunch"
    ],
    .lunch: [
        "Asian",
        "European",
        "American",
        "Latin American",
        "Middle Eastern",
        "Fast Food",
        "Vegetarian and Vegan",
        "Cafes and Bakeries"
    ],
    .dinner: [
        "Asian",
        "European",
        "American",
        "Latin American",
        "Middle Eastern",
        "Seafood",
        "Vegetarian and Vegan",
        "Barbecue and Grill"
    ],
    .dessert: [
        "Desserts and Sweets"
    ]
]
