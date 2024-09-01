//
//  CollectionItemCell.swift
//  Foodi
//
//  Created by Jack Robinson on 4/10/24.
//

import SwiftUI
import Kingfisher
import _MapKit_SwiftUI

struct CollectionItemCell: View {
    var item: CollectionItem
    var previewMode: Bool = false
    @ObservedObject var viewModel: CollectionsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Item image
            if let image = item.image {
                KFImage(URL(string: image))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "fork.knife")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .frame(width: 56, height: 56)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Location information
                    if let city = item.city, let state = item.state {
                        Text("\(city), \(state)")
                    } else if let city = item.city {
                        Text(city)
                    } else if let state = item.state {
                        Text(state)
                    } else if let name = item.postUserFullname {
                        Text("by @\(name)")
                    }
                    
                    // Added by information with collaborator indicator
                    if let addedByUid = item.addedByUid,
                       addedByUid != viewModel.selectedCollection?.uid, let addedByUsername = item.addedByUsername {
                        HStack(spacing: 2) {
                            Text("Added by @\(addedByUsername)")
                            Image(systemName: "link")
                                .foregroundColor(.red)
                                .font(.system(size: 10))
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    }
                }
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
            
            Spacer()
            
            // Notes icon (if applicable and not in preview mode)
            Button {
                viewModel.notesPreview = item
            } label: {
                if let notes = item.notes, !notes.isEmpty, !previewMode {
                    VStack {
                        Image(systemName: "square.and.pencil")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundStyle(Color("Colors/AccentColor"))
                        Text("notes")
                            .foregroundStyle(Color("Colors/AccentColor"))
                            .font(.custom("MuseoSansRounded-300", size: 10))
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(height: 72)
    }
}
