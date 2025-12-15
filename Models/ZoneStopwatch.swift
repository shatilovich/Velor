<<<<<<< HEAD
=======
//
//  ZoneStopwatch.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//

>>>>>>> 613f70b (new)
import Foundation

struct ZoneStopwatch {
    var elapsedSeconds: Int = 0
    var isRunning: Bool = false
<<<<<<< HEAD

    /// When the timer started (running state). Nil when paused/idle.
    var startedAt: Date? = nil
    /// Snapshot of elapsedSeconds at the moment of start/resume.
    var baseElapsedSeconds: Int = 0

=======
    var startedAt: Date? = nil
    var baseElapsedSeconds: Int = 0
    
>>>>>>> 613f70b (new)
    mutating func reset() {
        elapsedSeconds = 0
        isRunning = false
        startedAt = nil
        baseElapsedSeconds = 0
    }
}
