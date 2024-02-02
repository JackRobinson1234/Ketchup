//
//  StandardBackButtonModifier.swift
//  Foodi
//
//  Created by Jack Robinson on 2/2/24.
//

import UIKit

extension UINavigationController {
    func setupBlackBackChevron() {
        let backButtonImage = UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        
        // Customize the appearance of the navigation bar
        navigationBar.barTintColor = UIColor.black
        navigationBar.tintColor = UIColor.white
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        // Set the black back chevron
        navigationBar.backIndicatorImage = backButtonImage
        navigationBar.backIndicatorTransitionMaskImage = backButtonImage

        // Set the title of the back button
        topViewController?.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Set navigation bar to be translucent or not
        navigationBar.isTranslucent = false
    }
}
