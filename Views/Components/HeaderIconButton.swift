//
//  HeaderIconButton.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//

import SwiftUI

struct HeaderIconButton: View {
    let systemName: String
    let role: ButtonRole?
    let tint: Color
    let action: () -> Void
    let namespace: Namespace.ID?
    
    init(
        systemName: String,
        role: ButtonRole? = nil,
        tint: Color = .primary,
        action: @escaping () -> Void,
        namespace: Namespace.ID? = nil
    ) {
        self.systemName = systemName
        self.role = role
        self.tint = tint
        self.action = action
        self.namespace = namespace
    }
    
    var body: some View {
        if #available(iOS 26.0, *) {
            let button = Button(role: role, action: action) {
                Image(systemName: systemName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .circle)
            .buttonBorderShape(.circle)
            
            if let namespace {
                button.glassEffectID(systemName, in: namespace)
            } else {
                button
            }
        } else {
            Button(role: role, action: action) {
                Image(systemName: systemName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(tint)
            .buttonStyle(.plain)
            .background {
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .overlay(
                        Circle()
                            .stroke(AppColors.strokeSeparatorDefault(), lineWidth: AppColors.strokeWidthHairline)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
    }
}
