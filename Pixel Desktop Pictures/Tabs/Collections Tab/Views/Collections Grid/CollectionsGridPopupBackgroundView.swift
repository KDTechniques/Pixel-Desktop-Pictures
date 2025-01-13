//
//  CollectionsGridPopupBackgroundView.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2024-12-23.
//

import SwiftUI

struct CollectionsGridPopupBackgroundView: View {
    // MARK: - PROPERTIES
    @Environment(CollectionsTabViewModel.self) private var collectionsTabVM
    
    // MARK: - BODY
    var body: some View {
        Color.windowBackground
            .opacity(collectionsTabVM.popOverItem.isPresented ? 0.8 : 0)
            .onTapGesture { handleTap() }
    }
}

// MARK: - PREVIEWS
#Preview("Collections Grid Popup Background View") {
    CollectionsGridPopupBackgroundView()
        .environment(
            CollectionsTabViewModel(
                apiAccessKeyManager: .init(),
                collectionModelSwiftDataManager: .init(swiftDataManager: try! .init(appEnvironment: .mock)),
                imageQueryURLModelSwiftDataManager: .init(swiftDataManager: try! .init(appEnvironment: .mock)),
                errorPopupVM: .init()
            )
        )
}

extension CollectionsGridPopupBackgroundView {
    // MARK: - Handle Tap
    private func handleTap() {
        collectionsTabVM.presentPopup(false, for: collectionsTabVM.popOverItem.type)
    }
}
