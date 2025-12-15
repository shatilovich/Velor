<<<<<<< HEAD
import SwiftUI

=======
//
//  ZoneStatus.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//

import SwiftUI

>>>>>>> 613f70b (new)
enum ZoneStatus: Equatable {
    case idle
    case paused
    case ok
    case warn
    case danger
<<<<<<< HEAD

=======
    
>>>>>>> 613f70b (new)
    func stroke(for scheme: ColorScheme) -> Color {
        switch self {
        case .idle, .paused:
            return AppColors.borderNeutral(for: scheme, state: self)
        case .ok:
            return AppColors.statusOk
        case .warn:
            return AppColors.statusWarn
        case .danger:
            return AppColors.statusDanger
        }
    }
<<<<<<< HEAD

=======
    
>>>>>>> 613f70b (new)
    func label(for scheme: ColorScheme) -> Color {
        switch self {
        case .warn:   return AppColors.statusWarn
        case .danger: return AppColors.statusDanger
        case .ok:     return AppColors.statusOk
        case .paused: return AppColors.labelNeutral(for: scheme, state: .paused)
        case .idle:   return AppColors.labelNeutral(for: scheme, state: .idle)
        }
    }
}
