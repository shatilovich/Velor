<<<<<<< HEAD
import Foundation

struct AppSettings {
    /// Orange turns on at `warnPercent` of limit (0...1).
    var warnPercent: Double = 0.8

=======
//
//  AppSettings.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//

import Foundation

struct AppSettings {
    var warnPercent: Double = 0.8
    
>>>>>>> 613f70b (new)
    func limitSeconds(for zone: Zone) -> Int {
        let stored = UserDefaults.standard.integer(forKey: zone.limitKey)
        return stored == 0 ? zone.defaultLimitSeconds : stored
    }
<<<<<<< HEAD

    func setLimitSeconds(_ seconds: Int, for zone: Zone) {
        UserDefaults.standard.set(max(60, seconds), forKey: zone.limitKey)
    }

    func status(for zone: Zone, sw: ZoneStopwatch) -> ZoneStatus {
        if sw.elapsedSeconds == 0 && !sw.isRunning { return .idle }
        if !sw.isRunning { return .paused }

        let limit = max(60, limitSeconds(for: zone))
        let warnAt = Int(Double(limit) * warnPercent)

=======
    
    func setLimitSeconds(_ seconds: Int, for zone: Zone) {
        UserDefaults.standard.set(max(60, seconds), forKey: zone.limitKey)
    }
    
    func status(for zone: Zone, sw: ZoneStopwatch) -> ZoneStatus {
        if sw.elapsedSeconds == 0 && !sw.isRunning { return .idle }
        if !sw.isRunning { return .paused }
        
        let limit = max(60, limitSeconds(for: zone))
        let warnAt = Int(Double(limit) * warnPercent)
        
>>>>>>> 613f70b (new)
        if sw.elapsedSeconds >= limit { return .danger }
        if sw.elapsedSeconds >= warnAt { return .warn }
        return .ok
    }
<<<<<<< HEAD

=======
    
>>>>>>> 613f70b (new)
    func progress(for zone: Zone, sw: ZoneStopwatch) -> Double {
        let limit = Double(max(60, limitSeconds(for: zone)))
        return min(1.0, Double(sw.elapsedSeconds) / limit)
    }
}
