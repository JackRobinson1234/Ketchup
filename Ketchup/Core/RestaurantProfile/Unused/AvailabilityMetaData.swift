//
//  AvailabilityMetaData.swift
//  Foodi
//
//  Created by Jack Robinson on 4/19/24.
//

import SwiftUI

struct AvailabilityMetaData: View {
    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack{
                Text("Available")
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                Text("Reservations")
            }
            Divider()
            
            VStack{
                Text("Available")
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                Text("Delivery")
            }
            Divider()
            
            VStack{
                Text("Open")
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                Text("Reservations")
            }
        }
    }
}

#Preview {
    AvailabilityMetaData()
}
