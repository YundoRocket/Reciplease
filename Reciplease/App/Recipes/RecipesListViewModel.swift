//
//  RecipesListViewModel.swift
//  Reciplease
//
//  Created by Damien Rojo on 21.03.20.
//  Copyright © 2020 Damien Rojo. All rights reserved.
//

import Foundation

final class RecipesListViewModel {

    // MARK: - Properties
    
    private let ingredientsList: [String]
    private let searchRecipesListRepository: RecipesListRepositoryType
    private let favoritesRecipesListRepository: FavoritesRecipesListRepositoryType

    private let actions: Actions
    struct Actions {
        let didSelectItem: (Recipe) -> Void
    }

    init(
        ingredientsList: [String],
        actions: Actions,
        searchRecipesListRepository: RecipesListRepositoryType,
        favoritesRecipesListRepository: FavoritesRecipesListRepositoryType
    ) {
        self.ingredientsList = ingredientsList
        self.actions = actions
        self.searchRecipesListRepository = searchRecipesListRepository
        self.favoritesRecipesListRepository = favoritesRecipesListRepository
    }
    
    private var recipeItems: [RecipeItem] = [] {
        didSet {
            let items = recipeItems.map { Recipe(recipeItems: $0) }
            self.items?(items)
        }
    }

    private var favoriteRecipes: [Recipe] = [] {
        didSet {
            self.items?(favoriteRecipes)
        }
    }
    
    private var state = true

    // MARK: - Outputs

    var items: InputClosure<[Recipe]>?
    
    var dataIsLoaded: InputClosure<Bool>?
    
    var recipesArrayIsEmpty: InputClosure<Bool>?

    enum RecipeItem {
        case research(response: RecipesResponse.Recipe)
    }

    // MARK: - Inputs

    func viewDidLoad() {
        dataIsLoaded?(false)
        if !ingredientsList.isEmpty {
            searchRecipesListRepository.getRecipes(for: ingredientsList.joined(separator: "/")) { [weak self] recipesResponse in
                recipesResponse.hits.lazy.forEach { self?.recipeItems.append(.research(response: $0.recipe)) }
                self?.dataIsLoaded?(true)
                self?.state = true
            }
        } else {
            dataIsLoaded?(true)
            favoritesRecipesListRepository.getRecipes(for: nil) { [weak self] (recipes) in
                if recipes.isEmpty {
                    self?.recipesArrayIsEmpty?(true)
                } else {
                    self?.recipesArrayIsEmpty?(false)
                    self?.favoriteRecipes = recipes
                    self?.state = false
                }
            }
        }
    }

    func didSelectItem(at index: Int) {
        if state == true {
            guard recipeItems.indices.contains(index) else { return }
            let recip = Recipe(recipeItems: recipeItems[index])
            actions.didSelectItem(recip)

        } else {
            guard favoriteRecipes.indices.contains(index) else { return }
            let recipe = favoriteRecipes[index]
            actions.didSelectItem(recipe)
        }
    }
}

extension Recipe {
    init(recipeItems: RecipesListViewModel.RecipeItem) {
        switch recipeItems {
        case .research(response: let response):
            self = Recipe(response: response)
        }
    }
}