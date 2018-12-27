//
//  WorkoutManager.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import HealthKit

enum WorkoutState {

    case started, stopped

}

extension WorkoutState {

    func actionText() -> String {
        switch self {
        case .started:
            return "Stop"
        case .stopped:
            return "Start"
        }
    }
    
}

@available(watchOSApplicationExtension 4.0, *)
protocol WorkoutManagerDelegate: class {

    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState)
    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: Double)
    func notifyUpdateBioSampleCnt()

}

@available(watchOSApplicationExtension 4.0, *)
class WorkoutManager: NSObject {

    // MARK: - Properties

    private let healthStore = HKHealthStore()
    fileprivate let bioSampleManager = BioSampleManager()

    weak var delegate: WorkoutManagerDelegate?

    private(set) var state: WorkoutState = .stopped

    private var session: HKWorkoutSession?

    // MARK: - Initialization

    override init() {
        super.init()

        // Configure heart rate manager.
        bioSampleManager.delegate = self
    }

    // MARK: - Public API

    func start() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            // Another workout is running.
            return
        }
        NSLog("Started Tracking")

        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .other
        workoutConfiguration.locationType = .indoor

        // Create workout session.
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session!.delegate = self
        } catch {
            fatalError("Unable to create Workout Session!")
        }

        // Start workout session.
        healthStore.start(session!)

        // Update state to started and inform delegates.
        state = .started
        delegate?.workoutManager(self, didChangeStateTo: state)
    }

    func stop() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }
        NSLog("Stopped Tracking")

        // Stop querying heart rate.
        bioSampleManager.stop()

        // Stop the workout session.
        healthStore.end(session!)

        // Clear the workout session.
        session = nil

        // Update state to stopped and inform delegates.
        state = .stopped
        delegate?.workoutManager(self, didChangeStateTo: state)
    }

}

// MARK: - Workout Session Delegate

@available(watchOSApplicationExtension 4.0, *)
extension WorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            if fromState == .notStarted {
                bioSampleManager.start()
            }

        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        fatalError(error.localizedDescription)
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("Did generate \(event)")
    }
    
}

// MARK: BioSample Delegate

@available(watchOSApplicationExtension 4.0, *)
extension WorkoutManager: BioSampleManagerDelegate {

    func updateHeartRate(didChangeTo newHeartRate: Double) {
        delegate?.workoutManager(self, didChangeHeartRateTo: newHeartRate)
    }
    
    func notifyUpdateBioSampleCnt() {
        delegate?.notifyUpdateBioSampleCnt()
    }

}
