//
//  DesktopPictureScheduler.swift
//  Pixel Desktop Pictures
//
//  Created by Kavinda Dilshan on 2024-12-28.
//

import Foundation

actor DesktopPictureScheduler {
    // MARK: - INJECTED PROPERTIES
    private let timeIntervalType: DesktopPictureSchedulerIntervalsProtocol.Type
    private var timeIntervalSelection: TimeInterval
    private let backgroundTask: () -> ()
    
    // MARK: - ASSIGNED PROPERTIES
    private let defaults: UserDefaultsManager = .init()
    private let timeIntervalKey: String = UserDefaultKeys.timeIntervalSelection.rawValue
    private let executionTimeKey: String = UserDefaultKeys.executionTimeIntervalSince1970.rawValue
    private let taskIdentifier = "com.kdtechniques.Pixel-Desktop-Pictures.DesktopPictureScheduler.backgroundTask"
    private var scheduler: NSBackgroundActivityScheduler?
    private var currentTimeIntervalSince1970: TimeInterval {
        return Date().timeIntervalSince1970
    }
    
    // MARK: - INITIALIZER
    /// Initializes the DesktopPictureScheduler with the specified time interval model and background task.
    /// - Parameters:
    ///   - timeIntervalModel: The model that conforms to the DesktopPictureSchedulerIntervalsProtocol.
    ///   - backgroundTask: The background task to be executed.
    init(timeIntervalModel: DesktopPictureSchedulerIntervalsProtocol.Type, backgroundTask: @escaping () -> ()) {
        self.timeIntervalType = timeIntervalModel
        timeIntervalSelection = timeIntervalModel.defaultTimeInterval
        self.backgroundTask = backgroundTask
        
        Task { await initializeScheduler() }
    }
    
    // MARK: FUNCTIONS
    
    // MARK: INTERNAL FUNCTIONS
    
    // MARK: - on Change Of Time Interval Selection
    /// Handles changes to the time interval selection.
    /// - Parameter timeInterval: The new time interval selection.
    func onChangeOfTimeIntervalSelection(from timeInterval: DesktopPictureSchedulerIntervalsProtocol) async {
        // Save Time Interval Selection Value to User Defaults
        let timeIntervalSelection: TimeInterval = timeInterval.timeInterval
        await saveTimeIntervalSelectionToUserDefaults(from: timeIntervalSelection)
        
        // Calculate Execution Time Interval Since 1970, Then Schedule Task, and Save to User Defaults
        await calculateScheduleSaveExecutionTimeIntervalSince1970(with: timeIntervalSelection)
    }
    
    // MARK: PRIVATE FUNCTIONS
    
    // MARK: - Initialize Scheduler
    /// Initializes the scheduler by setting the time interval and scheduling the background task.
    private func initializeScheduler() async {
        // Assign Time Interval Selection Value to A Property to Avoid Using User Defaults Most of the Time
        let timeIntervalSelection: TimeInterval = await getTimeIntervalSelectionFromUserDefaults()
        self.timeIntervalSelection = timeIntervalSelection
        
        let timeIntervalForScheduler: TimeInterval? = await calculateTimeIntervalForScheduler()
        try? await scheduleBackgroundTask(with: timeIntervalForScheduler)
    }
    
    // MARK: - Calculate Schedule Save Execution Time Interval Since 1970
    /// Calculates, schedules, and saves the execution time interval since 1970.
    /// - Parameter timeIntervalSelection: The selected time interval.
    private func calculateScheduleSaveExecutionTimeIntervalSince1970(with timeIntervalSelection: TimeInterval) async {
        // Calculate Execution Time Interval Since 1970 from New Time Interval Selection Value
        let executionTimeIntervalSince1970: TimeInterval = await calculateExecutionTimeIntervalSince1970(from: timeIntervalSelection)
        
        // Schedule Background Task by Time Interval Selection Value
        try? await scheduleBackgroundTask(with: timeIntervalSelection)
        
        // Save Execution Time Interval Since 1970 to User Defaults
        await saveExecutionTimeSince1970ToUserDefaults(from: executionTimeIntervalSince1970)
    }
    
    // MARK: - Calculate Execution Time Interval Since 1970
    /// Calculates the execution time interval since 1970 based on the selected time interval.
    /// - Parameter timeIntervalSelection: The selected time interval.
    /// - Returns: The execution time interval since 1970.
    private func calculateExecutionTimeIntervalSince1970(from timeIntervalSelection: TimeInterval) async -> TimeInterval {
        // Add Time Interval Selection Value to Current Date to get the Execution Time in the Future
        let executionTimeIntervalSince1970: TimeInterval = Date().addingTimeInterval(timeIntervalSelection).timeIntervalSince1970
        return executionTimeIntervalSince1970
    }
    
    // MARK: - Calculate Time Interval for Scheduler
    /// Calculates the time interval for the scheduler based on the execution time.
    /// - Returns: The calculated time interval for the scheduler.
    private func calculateTimeIntervalForScheduler() async -> TimeInterval? {
        let executionTimeIntervalSince1970: TimeInterval = await getExecutionTimeIntervalSince1970FromUserDefaults(otherwiseWith: timeIntervalSelection)
        
        // Calculate Time Interval for the `NSBackgroundActivityScheduler`
        let activityTimeInterval: TimeInterval = executionTimeIntervalSince1970 - currentTimeIntervalSince1970
        
        // Handle When User Has Passed the Execution Time and Opened the App
        guard activityTimeInterval > 0 else {
            return nil
        }
        
        // Return Positive `activityTimeInterval` Value When User Opens the App Before the Execution Time
        return activityTimeInterval
    }
    
    // MARK: User Defaults Related
    
    // MARK: - Get Time Interval Selection from User Defaults
    /// Retrieves the time interval selection value from User Defaults.
    /// - Returns: The time interval selection value.
    private func getTimeIntervalSelectionFromUserDefaults() async -> TimeInterval {
        // Try to Get Time Interval Selection Value from User Defaults
        guard let timeIntervalSelection: TimeInterval = await defaults.get(key: timeIntervalKey) as? TimeInterval else {
            // Get the Default Time Interval Value from `DesktopPictureSchedulerIntervalsProtocol`
            let defaultTimeInterval: TimeInterval = timeIntervalType.defaultTimeInterval
            
            return defaultTimeInterval
        }
        
        // Return Saved Time Interval Selection Value from User Defaults
        return timeIntervalSelection
    }
    
    // MARK: - Get Execution Time Interval Since 1970 from User Defaults
    /// Retrieves the execution time interval since 1970 from User Defaults or calculates a new one if not found.
    /// - Parameter timeIntervalSelection: The selected time interval.
    /// - Returns: The execution time interval since 1970.
    private func getExecutionTimeIntervalSince1970FromUserDefaults(otherwiseWith timeIntervalSelection: TimeInterval) async -> TimeInterval {
        // Try to get Saved Execution Time Interval Since 1970 from User Defaults
        guard let savedExecutionTimeIntervalSince1970: TimeInterval = await defaults.get(key: executionTimeKey) as? TimeInterval else {
            // Create New Execution Time Interval Since 1970 on User Defaults Failure
            let newExecutionTimeIntervalSince1970: TimeInterval = await calculateExecutionTimeIntervalSince1970(from: timeIntervalSelection)
            
            // Save New Execution Time Interval Since 1970 to User Defaults
            await saveExecutionTimeSince1970ToUserDefaults(from: newExecutionTimeIntervalSince1970)
            return newExecutionTimeIntervalSince1970
        }
        
        // Return Saved Execution Time Interval Since 1970 Value from User Defaults
        return savedExecutionTimeIntervalSince1970
    }
    
    // MARK: - Save Time Interval Selection to User Defaults
    /// Saves the time interval selection value to User Defaults.
    /// - Parameter timeIntervalSelection: The selected time interval.
    private func saveTimeIntervalSelectionToUserDefaults(from timeIntervalSelection: TimeInterval) async {
        await defaults.save(key: timeIntervalKey, value: timeIntervalSelection)
        self.timeIntervalSelection = timeIntervalSelection
    }
    
    // MARK: - Save Execution Time Since 1970 to User Defaults
    /// Saves the execution time interval since 1970 to User Defaults.
    /// - Parameter executionTimeIntervalSince1970: The execution time interval since 1970.
    private func saveExecutionTimeSince1970ToUserDefaults(from executionTimeIntervalSince1970: TimeInterval) async {
        await defaults.save(key: executionTimeKey, value: executionTimeIntervalSince1970)
    }
    
    // MARK: - Schedule Background Task
    /// Schedules the background task with the given time interval.
    /// - Parameter timeInterval: The time interval for the scheduler.
    private func scheduleBackgroundTask(with timeInterval: TimeInterval?) async throws {
        guard let timeInterval: TimeInterval else {
            // Nil `timeInterval` Value Means User Has Passed the Execution Time and Opened the App
            // So, Immediately Call the Background Task
            await performBackgroundTask()
            
            // Calculate Execution Time Interval Since 1970, Then Schedule Task, and Save to User Defaults
            await calculateScheduleSaveExecutionTimeIntervalSince1970(with: timeIntervalSelection)
            return
        }
        
        let activity: NSBackgroundActivityScheduler = .init(identifier: taskIdentifier)
        activity.repeats = false  // Set repeats to false so that we can accurately set intervals by calculating them for different edge cases.
        activity.interval = timeInterval
        activity.tolerance = min(activity.interval * 0.1, 30 * 60) // Max tolerance is 30 min
        activity.schedule { completion in
            Task { [weak self] in
                guard let self else {
                    print("Error: Task got deallocated.")
                    completion(.deferred)
                    throw URLError(.badURL)
                }
                
                await performBackgroundTask()
                completion(.finished)
                
                // Rescheduling Upon Completion as We Don't Repeat the Scheduler
                // Calculate Execution Time Interval Since 1970, Then Schedule Task, and Save to User Defaults
                await calculateScheduleSaveExecutionTimeIntervalSince1970(with: timeIntervalSelection)
            }
        }
        
        // Assign the new activity
        scheduler = activity
    }
    
    // MARK: - Perform Background Task
    /// Performs the background task.
    private func performBackgroundTask() async {
        backgroundTask()
    }
}


enum DesktopPictureSchedulerError: Error {
    case schedulingFailed
    case invalidTimeInterval
    case taskDeallocated
}
