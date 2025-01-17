//
//  TabsViewModel.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2024-12-25.
//

import Foundation

@MainActor
@Observable final class TabsViewModel {
    // MARK: - PROPERTIES
    private(set) var tabSelection: TabItemsModel = .main
    private(set) var selectedTabContentHeight: CGFloat = .infinity
    
    // MARK: FUNCTIONS
    
    // MARK: - Set Tab Selection
    func setTabSelection(_ tab: TabItemsModel) {
        tabSelection = tab
    }
    
    // MARK: - Set Tab Content Height
    func setTabContentHeight(height: CGFloat, from tab: TabItemsModel) {
        guard tab == tabSelection else { return }
        selectedTabContentHeight = height
    }
}
