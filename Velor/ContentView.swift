//
//  ContentView.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//



import SwiftUI

// MARK: - Glass Icon Button

private struct HeaderIconButton: View {
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
            // Pre-iOS 26 fallback
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


// MARK: - Header Buttons Container

@available(iOS 26.0, *)
private struct HeaderButtonsContainer: View {
    @Namespace private var glassNamespace
    let onResetTap: () -> Void
    let onSettingsTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Text("Velor")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            GlassEffectContainer {
                HStack(spacing: 12) {
                    HeaderIconButton(
                        systemName: "arrow.counterclockwise",
                        role: .destructive,
                        action: onResetTap,
                        namespace: glassNamespace
                    )
                    .accessibilityLabel("Сброс")
                    .accessibilityHint("Сбросить все секундомеры")

                    HeaderIconButton(
                        systemName: "gearshape",
                        action: onSettingsTap,
                        namespace: glassNamespace
                    )
                    .accessibilityLabel("Настройки")
                    .accessibilityHint("Открыть меню настроек")
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var store = StopwatchesStore()
    @AppStorage("warnPercent") private var warnPercent: Double = 0.8
    @AppStorage("appTheme") private var appTheme: String = "system" // system | light | dark
    private var settings: AppSettings { AppSettings(warnPercent: warnPercent) }

    private var hasRunningTimers: Bool {
        store.items.values.contains(where: { $0.isRunning })
    }

    @State private var showMenu = false
    @State private var confirmResetAll = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 16) {
                    header

                    ZoneGrid(
                        settings: settings,
                        items: store.items,
                        onTapZone: { zone in
                            let isRunning = store.items[zone]?.isRunning ?? false
                            if isRunning {
                                Haptics.pause()
                            } else {
                                Haptics.start()
                            }
                            store.toggle(zone)
                        }
                    )
                    .padding(.top, 8)

                    if hasRunningTimers {
                        if #available(iOS 26.0, *) {
                            Button {
                                Haptics.pause()
                                store.pauseAll()
                            } label: {
                                Text("Остановить все")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(effectiveScheme == .dark ? .glass(.clear) : .glass)
                            .controlSize(.large)
                            .padding(.top, 4)
                            .accessibilityLabel("Остановить все")
                            .accessibilityHint("Поставить на паузу все запущенные таймеры")
                        } else {
                            Button {
                                Haptics.pause()
                                store.pauseAll()
                            } label: {
                                Text("Остановить все")
                                    .font(.system(size: 15, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .foregroundStyle(.primary)
                            .background(
                                Capsule()
                                    .fill(.thinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(AppColors.strokeSeparatorSubtle(), lineWidth: AppColors.strokeWidthHairline)
                                    )
                            )
                            .padding(.top, 4)
                            .accessibilityLabel("Остановить все")
                            .accessibilityHint("Поставить на паузу все запущенные таймеры")
                        }
                    }

                    Spacer()

                    footerHint
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showMenu) {
                MenuView(
                    warnPercent: $warnPercent,
                    appTheme: $appTheme,
                    getLimitSeconds: { zone in settings.limitSeconds(for: zone) },
                    setLimitMinutes: { zone, minutes in
                        UserDefaults.standard.set(max(60, minutes * 60), forKey: zone.limitKey)
                    }
                )
                .presentationBackground(.ultraThinMaterial)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .alert("Сбросить все секундомеры?", isPresented: $confirmResetAll) {
                Button("Отменить", role: .cancel) {}
                Button("Сбросить", role: .destructive) { store.resetAll() }
            } message: {
                Text("Обнулим все 4 зоны. Это действие нельзя отменить.")
            }
            .onAppear {
                store.settingsProvider = { settings }
                store.appDidBecomeActive()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                store.appDidBecomeActive()
            case .inactive, .background:
                store.appWillResignActive()
            @unknown default:
                break
            }
        }
        .preferredColorSchemeIfNeeded(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }

    private var effectiveScheme: ColorScheme {
        colorScheme ?? systemScheme
    }

    private var background: some View {
        AppColors.backgroundPrimary(for: effectiveScheme)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var header: some View {
        if #available(iOS 26.0, *) {
            HeaderButtonsContainer(
                onResetTap: {
                    Haptics.resetTap()
                    confirmResetAll = true
                },
                onSettingsTap: {
                    Haptics.tap()
                    showMenu = true
                }
            )
        } else {
            HStack(alignment: .center) {
                HStack(spacing: 10) {
                    Text("Velor")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                HStack(spacing: 12) {
                    HeaderIconButton(
                        systemName: "arrow.counterclockwise",
                        role: .destructive
                    ) {
                        Haptics.resetTap()
                        confirmResetAll = true
                    }
                    .accessibilityLabel("Сброс")
                    .accessibilityHint("Сбросить все секундомеры")

                    HeaderIconButton(
                        systemName: "gearshape"
                    ) {
                        Haptics.tap()
                        showMenu = true
                    }
                    .accessibilityLabel("Настройки")
                    .accessibilityHint("Открыть меню настроек")
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var footerHint: some View {
        EmptyView()
    }
}



// MARK: - Adaptive Glass Button

private struct AdaptiveGlassButtonStyle: ViewModifier {
    let scheme: ColorScheme

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(scheme == .dark ? .glass(.clear) : .glass)
                .buttonBorderShape(.circle)
        } else {
            content
                .foregroundStyle(.primary)
                .background(
                    Circle()
                        .fill(.thinMaterial)
                        .overlay(
                            Circle()
                                .stroke(AppColors.strokeSeparatorDefault(), lineWidth: AppColors.strokeWidthHairline)
                        )
                )
        }
    }
}

private extension View {
    func adaptiveGlassButton(scheme: ColorScheme) -> some View {
        modifier(AdaptiveGlassButtonStyle(scheme: scheme))
    }
}

// MARK: - Glass Split Button

private struct SplitIconSegmentStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? AppColors.opacityPressedFill : 0))
            )
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct GlassSplitIconButton: View {
    let leftSystemName: String
    let rightSystemName: String
    let leftAction: () -> Void
    let rightAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(role: .destructive, action: leftAction) {
                Image(systemName: leftSystemName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SplitIconSegmentStyle())
            .accessibilityLabel("Сброс")
            .accessibilityHint("Сбросить все секундомеры")

            // Center divider
            Rectangle()
                .fill(AppColors.divider())
                .frame(width: 1)
                .padding(.vertical, 12)

            Button(action: rightAction) {
                Image(systemName: rightSystemName)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 52, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(SplitIconSegmentStyle())
            .accessibilityLabel("Настройки")
            .accessibilityHint("Открыть меню настроек")
        }
        .foregroundStyle(.primary)
        .frame(height: 44)
        .clipShape(Capsule())
        .background {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .capsule)
            } else {
                Capsule()
                    .fill(.thinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(AppColors.strokeSeparatorDefault(), lineWidth: AppColors.strokeWidthHairline)
                    )
                    .shadow(color: .black.opacity(AppColors.shadowOpacityFallback), radius: 10, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Zone grid

private struct ZoneGrid: View {
    let settings: AppSettings
    let items: [Zone: ZoneStopwatch]

    let onTapZone: (Zone) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionBlock(title: "Ресницы") {
                TwoCardsRow(
                    left: .lashLeft,
                    right: .lashRight,
                    settings: settings,
                    items: items,
                    onTapZone: onTapZone
                )
            }

            SectionBlock(title: "Брови") {
                TwoCardsRow(
                    left: .browLeft,
                    right: .browRight,
                    settings: settings,
                    items: items,
                    onTapZone: onTapZone
                )
            }
        }
        .padding(.top, 4)
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 2)
                .padding(.bottom, 2)

            content
        }
    }
}

private struct TwoCardsRow: View {
    let left: Zone
    let right: Zone

    let settings: AppSettings
    let items: [Zone: ZoneStopwatch]
    let onTapZone: (Zone) -> Void

    var body: some View {
        HStack(spacing: 14) {
            card(left)
            card(right)
        }
    }

    @ViewBuilder
    private func card(_ zone: Zone) -> some View {
        let sw = items[zone] ?? ZoneStopwatch()
        let status = settings.status(for: zone, sw: sw)
        let limit = settings.limitSeconds(for: zone)
        let progress = settings.progress(for: zone, sw: sw)

        ZoneCard(
            zone: zone,
            elapsed: sw.elapsedSeconds,
            limit: limit,
            progress: progress,
            status: status,
            isRunning: sw.isRunning,
            onTap: { onTapZone(zone) }
        )
    }
}

private struct ZoneCard: View {
    let zone: Zone
    let elapsed: Int
    let limit: Int
    let progress: Double
    let status: ZoneStatus
    let isRunning: Bool

    let onTap: () -> Void

    @State private var isPressing = false
    @State private var shouldPulse = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button {
            isPressing = false
            onTap()
        } label: {
            ZStack {
                let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

                if #available(iOS 26.0, *) {
                    shape
                        .fill(AppColors.cardSurface(for: scheme))
                        .overlay {
                            shape
                                .fill(.clear)
                                .glassEffect(.regular.interactive(), in: shape)
                        }
                        .overlay(
                            shape.stroke(status.stroke(for: scheme), lineWidth: AppColors.strokeWidthAccent)
                        )
                } else {
                    shape
                        .fill(AppColors.cardSurface(for: scheme))
                        .overlay(
                            shape.stroke(AppColors.strokeSeparatorSubtle(), lineWidth: AppColors.strokeWidthHairline)
                        )
                        .overlay(
                            shape.stroke(status.stroke(for: scheme), lineWidth: AppColors.strokeWidthAccent)
                        )
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(zone.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Ring(progress: progress, stroke: status.stroke(for: scheme))
                            .frame(width: 40, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(timeString(elapsed))
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)

                        Text(statusLine(elapsed: elapsed, limit: limit, status: status))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(status.label(for: scheme))
                    }

                }
                .padding(14)
            }
            .frame(height: 148)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressing ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
        .scaleEffect(shouldPulse ? 1.05 : 1.0)
        .animation(
            shouldPulse
                ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                : .default,
            value: shouldPulse
        )
        .onChange(of: status) { _, newStatus in
            withAnimation {
                shouldPulse = newStatus == .danger
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressing = true }
                .onEnded { _ in isPressing = false }
        )
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func statusLine(elapsed: Int, limit: Int, status: ZoneStatus) -> String {
        let limitText = timeString(limit)
        switch status {
        case .idle:
            return "Лимит \(limitText)"
        case .paused:
            return "Пауза · лимит \(limitText)"
        case .ok:
            return "Идёт · лимит \(limitText)"
        case .warn:
            return "Почти лимит · \(limitText)"
        case .danger:
            return "Время вышло · \(limitText)"
        }
    }
}

private struct Ring: View {
    let progress: Double
    let stroke: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.ringTrackStroke(), lineWidth: AppColors.ringLineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(stroke, style: StrokeStyle(lineWidth: AppColors.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.easeOut(duration: 0.2), value: progress)
    }
}

// MARK: - Menu Sheet

private struct MenuView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var warnPercent: Double
    @Binding var appTheme: String

    let getLimitSeconds: (Zone) -> Int
    let setLimitMinutes: (Zone, Int) -> Void

    @State private var limitsMinutes: [Zone: Int] = [:]
    @State private var confirmResetDefaults = false

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                Form {
                    Section(
                        header: Text("Лимиты по зонам")
                    ) {
                        ForEach(Zone.allCases) { zone in
                            Stepper(
                                value: Binding(
                                    get: { limitsMinutes[zone] ?? max(1, getLimitSeconds(zone) / 60) },
                                    set: { newValue in
                                        Haptics.tap()
                                        limitsMinutes[zone] = newValue
                                        setLimitMinutes(zone, newValue)
                                    }
                                ),
                                in: 1...30
                            ) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(zone.title.replacingOccurrences(of: "\n", with: " "))
                                        Text(zone.subtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\((limitsMinutes[zone] ?? max(1, getLimitSeconds(zone) / 60))) мин")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section(header: Text("Предупреждение")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Оранжевый порог")
                            Slider(value: $warnPercent, in: 0.6...0.9, step: 0.05)
                            Text("Оранжевый при ~\(Int(warnPercent * 100))% лимита")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section(header: Text("Тема")) {
                        Picker("Оформление", selection: $appTheme) {
                            Text("Системная").tag("system")
                            Text("Светлая").tag("light")
                            Text("Тёмная").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: appTheme) { _, _ in
                            Haptics.tap()
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            Haptics.resetTap()
                            confirmResetDefaults = true
                        } label: {
                            Text("Сбросить настройки")
                        }
                    } footer: {
                        Text("Вернём лимиты зон и порог предупреждения к значениям по умолчанию.")
                    }
                }
                // Let the glass background show through.
                .scrollContentBackground(.hidden)
                // Make rows feel like glass cards and stay readable in medium detent.
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppColors.strokeSeparatorSubtle(), lineWidth: AppColors.strokeWidthHairline)
                        )
                )
            }
            .navigationTitle("Меню")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
            // Hide the navigation bar background so title and actions sit directly on the glass content.
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Сбросить настройки?", isPresented: $confirmResetDefaults) {
                Button("Отменить", role: .cancel) {}
                Button("Сбросить", role: .destructive) {
                    Haptics.resetTap()
                    // Reset per-zone limits to defaults by removing stored overrides
                    for z in Zone.allCases {
                        UserDefaults.standard.removeObject(forKey: z.limitKey)
                    }
                    // Reset warning threshold to default (80%)
                    warnPercent = 0.8

                    // Refresh local UI state
                    for z in Zone.allCases {
                        limitsMinutes[z] = max(1, getLimitSeconds(z) / 60)
                    }
                }
            } message: {
                Text("Все лимиты и пороги вернутся к значениям по умолчанию.")
            }
        }
        .preferredColorSchemeIfNeeded(colorScheme)
        .onAppear {
            // Initialize local minutes from persisted limits so steppers are interactive and UI updates immediately.
            for z in Zone.allCases {
                limitsMinutes[z] = max(1, getLimitSeconds(z) / 60)
            }
            warnPercent = min(max(warnPercent, 0.6), 0.9)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
