//
//  FacetsView.swift
//  Foodi
//
//  Created by Jack Robinson on 4/23/24.
//

import SwiftUI
import InstantSearchSwiftUI
struct FacetsView: View {
  
  @ObservedObject var dynamicFacetListController: DynamicFacetListObservableController
    
  var body: some View {
    ScrollView {
      ForEach(dynamicFacetListController.orderedFacets, id: \.attribute) { orderedFacet in
        VStack(spacing: 0) {
          // Facet header
          ZStack {
            Color(.systemGray5)
            Text(orderedFacet.attribute.rawValue)
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 5)
          }
          // Facet values
          ForEach(orderedFacet.facets, id: \.value) { facet in
            VStack(spacing: 0) {
              FacetRow(facet: facet,
                      isSelected: dynamicFacetListController.isSelected(facet, for: orderedFacet.attribute))
                .onTapGesture {
                  dynamicFacetListController.toggle(facet, for: orderedFacet.attribute)
                }
                .frame(minHeight: 44, idealHeight: 44, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 5)
            }
          }
        }
      }
    }
  }
  
}
