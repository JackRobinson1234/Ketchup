//
//  Recipe.swift
//  Ketchup
//
//  Created by Jack Robinson on 6/10/24.
//

import Foundation
struct Recipe: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var cookingTime: Int?
    var dietary: [String]?
    var instructions: [Instruction]?
    var ingredients: [Ingredient]?
    var difficulty: RecipeDifficulty?
    var servings: Int?
    var postId: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.cookingTime = try container.decodeIfPresent(Int.self, forKey: .cookingTime)
        self.dietary = try container.decodeIfPresent([String].self, forKey: .dietary)
        self.instructions = try container.decodeIfPresent([Instruction].self, forKey: .instructions)
        self.ingredients = try container.decodeIfPresent([Ingredient].self, forKey: .ingredients)
        self.difficulty = try container.decodeIfPresent(RecipeDifficulty.self, forKey: .difficulty)
        self.servings = try container.decodeIfPresent(Int.self, forKey: .servings)
        self.postId = try container.decode(String.self, forKey: .postId)
    }
    
    init(
        id: String,
        name: String,
        cookingTime: Int? = nil,
        dietary: [String]? = nil,
        instructions: [Instruction]? = nil,
        ingredients: [Ingredient]? = nil,
        difficulty: RecipeDifficulty? = nil,
        servings: Int? = nil,
        postId: String
    ) {
        self.id = id
        self.name = name
        self.cookingTime = cookingTime
        self.dietary = dietary
        self.instructions = instructions
        self.ingredients = ingredients
        self.difficulty = difficulty
        self.servings = servings
        self.postId = postId
    }
    
}


struct Instruction: Codable, Hashable {
    var title: String
    var description: String
}

struct Ingredient: Codable, Hashable {
    var quantity: String
    var item: String
}
enum RecipeDifficulty: Int, Codable {
    case easy
    case medium
    case hard
    var text: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
            
        }
    }
}

