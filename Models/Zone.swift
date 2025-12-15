<<<<<<< HEAD
import SwiftUI

enum Zone: String, CaseIterable, Identifiable {
    case lashLeft, lashRight, browLeft, browRight

    var id: String { rawValue }

=======
//
//  Zone.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//

import Foundation
import CoreGraphics

enum Zone: String, CaseIterable, Identifiable {
    case lashLeft, lashRight, browLeft, browRight
    
    var id: String { rawValue }
    
>>>>>>> 613f70b (new)
    var title: String {
        switch self {
        case .lashLeft:  return "Левая\nресница"
        case .lashRight: return "Правая\nресница"
        case .browLeft:  return "Левая\nбровь"
        case .browRight: return "Правая\nбровь"
        }
    }
<<<<<<< HEAD

=======
    
>>>>>>> 613f70b (new)
    var subtitle: String {
        switch self {
        case .lashLeft, .lashRight: return "Ресницы"
        case .browLeft, .browRight: return "Брови"
        }
    }
<<<<<<< HEAD

    var limitKey: String { "limitSeconds_\(rawValue)" }

=======
    
    var limitKey: String { "limitSeconds_\(rawValue)" }
    
>>>>>>> 613f70b (new)
    var defaultLimitSeconds: Int {
        switch self {
        case .lashLeft, .lashRight: return 10 * 60
        case .browLeft, .browRight: return 6 * 60
        }
    }
<<<<<<< HEAD

    /// Relative position on face canvas (0...1)
=======
    
>>>>>>> 613f70b (new)
    var faceAnchor: CGPoint {
        switch self {
        case .lashLeft:  return CGPoint(x: 0.32, y: 0.42)
        case .lashRight: return CGPoint(x: 0.68, y: 0.42)
        case .browLeft:  return CGPoint(x: 0.32, y: 0.33)
        case .browRight: return CGPoint(x: 0.68, y: 0.33)
        }
    }
}
