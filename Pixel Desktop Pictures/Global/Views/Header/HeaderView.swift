//
//  HeaderView.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2024-12-22.
//

import SwiftUI

struct HeaderView: View {
    // MARK: - BODY
    var body: some View {
        HStack {
            LogoNTitleView()
            Spacer()
            TabItemsView()
        }
        .padding()
    }
}

// MARK: - PREVIEWS
#Preview("Header View") {
    HeaderView()
        .frame(width: TabItems.allWindowWidth)
        .background(Color.windowBackground)
        .environment(TabsViewModel())
}
