//
//  APIAccessKeyManager.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2025-01-07.
//

import Foundation

/**
 A class responsible for managing the API access key, its validation, and status updates.
 It interacts with UserDefaults for persistence and ensures the access key's validity through API calls.
 */
@MainActor
@Observable final class APIAccessKeyManager {
    // MARK: - PROPERTIES
    let defaults: UserDefaultsManager = .init()
    
    /// Current status of the API access key, which updates and triggers status change handling logic.
    var apiAccessKeyStatus: APIAccessKeyValidityStatusModel = .notFound {
        didSet {
            guard oldValue != apiAccessKeyStatus else { return }
            Task { await onAPIAccessKeyStatusChange(apiAccessKeyStatus) }
        }
    }
    
    // MARK: FUNCTIONS
    
    // MARK: INTERNAL FUNCTIONS
    
    // MARK: - Initialize API Access Key Manager
    /// Initializes the API Access Key Manager by fetching and assigning the API access key status from UserDefaults.
    /// - Throws: An error if fetching the access key status from UserDefaults fails.
    func initializeAPIAccessKeyManager() async throws {
        try await getNAssignAPIAccessKeyStatusFromUserDefaults()
        print("API Access Key Manager is initialized!")
    }
    
    // MARK: - API Access Key Checkup
    /// Checks if an API access key is stored in UserDefaults and attempts to connect it.
    /// If no key is found, the status is set to `.notFound`.
    func apiAccessKeyCheckup() async {
        guard let apiAccessKey: String = await getAPIAccessKeyFromUserDefaults() else {
            apiAccessKeyStatus = .notFound
            return
        }
        
        await connectAPIAccessKey(key: apiAccessKey)
    }
    
    // MARK: - Connect API Access Key
    /// Attempts to connect and validate the provided API access key.
    /// - Parameter key: The API access key to validate.
    func connectAPIAccessKey(key: String) async {
        guard !key.isEmpty else { return }
        
        apiAccessKeyStatus = .validating
        let imageAPIService: UnsplashImageAPIService = .init(apiAccessKey: key)
        
        do {
            try await imageAPIService.validateAPIAccessKey()
            apiAccessKeyStatus = .connected
            await saveAPIAccessKeyToUserDefaults(key)
        } catch let error as URLError {
            print(error.localizedDescription)
            apiAccessKeyStatus = (error.code == .notConnectedToInternet) ? .failed : .invalid
        } catch {
            print(error.localizedDescription)
            apiAccessKeyStatus = .invalid
        }
    }
    
    // MARK: PRIVATE FUNCTIONS
    
    // MARK: - getAPIAccessKeyFromUserDefaults
    /// Retrieves the API access key stored in UserDefaults.
    /// - Returns: The stored API access key as a `String`, or `nil` if not found.
    private func getAPIAccessKeyFromUserDefaults() async -> String? {
        guard let apiAccessKey: String = await defaults.get(key: .apiAccessKey) as? String else {
            return nil
        }
        
        return apiAccessKey
    }
    
    // MARK: - On API Access Key Status Change
    /// Handles changes to the API access key status and updates the stored status in UserDefaults.
    /// - Parameter status: The new API access key status.
    private func onAPIAccessKeyStatusChange(_ status: APIAccessKeyValidityStatusModel) async {
        do {
            switch status {
            case .notFound, .validating, .failed:
                try await saveAPIAccessKeyStatusToUserDefaults(.notFound)
            case .invalid:
                try await saveAPIAccessKeyStatusToUserDefaults(.invalid)
            case .connected:
                try await saveAPIAccessKeyStatusToUserDefaults(.connected)
            }
        } catch {
            print("Error: Saving `\(status)` status to user defaults. \(error.localizedDescription)")
        }
    }
    
    // MARK: - Save API Access Key to User Defaults
    /// Saves the provided API access key to UserDefaults.
    /// - Parameter key: The API access key to save.
    private func saveAPIAccessKeyToUserDefaults(_ key: String) async {
        await defaults.save(key: .apiAccessKey, value: key)
    }
    
    // MARK: - Save API Access Key Status to User Defaults
    /// Saves the provided API access key status to UserDefaults.
    /// - Parameter status: The API access key status to save.
    /// - Throws: An error if saving the status to UserDefaults fails.
    private func saveAPIAccessKeyStatusToUserDefaults(_ status: APIAccessKeyValidityStatusModel) async throws {
        try await defaults.saveModel(key: .apiAccessKeyStatusKey, value: status)
    }
    
    // MARK: - Get & Assign API Access Key Status from User Defaults
    /// Retrieves and assigns the API access key status stored in UserDefaults.
    /// - Throws: An error if fetching the access key status from UserDefaults fails.
    private func getNAssignAPIAccessKeyStatusFromUserDefaults() async throws {
        guard let apiAccessKeyStatus: APIAccessKeyValidityStatusModel = try await defaults.getModel(key: .apiAccessKeyStatusKey, type: APIAccessKeyValidityStatusModel.self) else {
            apiAccessKeyStatus = .notFound
            return
        }
        
        self.apiAccessKeyStatus = apiAccessKeyStatus
    }
}
