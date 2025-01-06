//
//  ContentNotAvailableModel.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2025-01-04.
//

import SwiftUI

enum ContentNotAvailableModel: CaseIterable {
    case apiAccessKeyNotFound, noInternetConnection
    
    var title: String {
        switch self {
        case .apiAccessKeyNotFound:
            return "API Access Key Not Found"
        case .noInternetConnection:
            return "Failed to Fetch Content"
        }
    }
    
    @ViewBuilder
    func description(action: @escaping () -> Void) -> some View {
        switch self {
        case .apiAccessKeyNotFound:
            HStack(spacing: 4) {
                Text("Go to")
                
                Button {
                    action()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .foregroundStyle(Color.accentColor)
                    .underline()
                }
                .buttonStyle(.plain)
                
                Text("tab to add one.")
            }
            .foregroundStyle(.secondary)
        case .noInternetConnection:
            Text("Make sure the Mac is connected to the internet.")
                .foregroundStyle(.secondary)
        }
    }
}