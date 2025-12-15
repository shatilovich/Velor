//
//  ContentView.swift
//  Velor
//
//  Created by Shatilovich.R on 12.12.2025.
//



import SwiftUI
import Combine
import UIKit

// MARK: - Haptics

enum Haptics {
    // ✅ Предотвращение спама haptics
    private static var lastHapticTime: [String: Date] = [:]
    private static let minimumInterval: TimeInterval = 0.1

    private static func canTrigger(for key: String) -> Bool {
        guard let last = lastHapticTime[key] else {
            lastHapticTime[key] = Date()
            return true
        }

        let interval = Date().timeIntervalSince(last)
        if interval >= minimumInterval {
            lastHapticTime[key] = Date()
            return true
        }
        return false
    }

    private static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, key: String) {
        guard canTrigger(for: key) else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType, key: String) {
        guard canTrigger(for: key) else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }

    static func tap() {
        impact(.light, key: "tap")
    }

    static func start() {
        impact(.light, key: "start")
    }

    static func pause() {
        impact(.soft, key: "pause")
    }

    static func resetTap() {
        impact(.rigid, key: "resetTap")
    }

    static func warning() {
        notify(.warning, key: "warning")
    }

    static func error() {
        notify(.error, key: "error")
        // Optional extra punch, also throttled under its own key
        impact(.heavy, key: "errorHeavy")
    }
}

// MARK: - Palette

enum AppColors {
    // Neutral borders
    static let borderNeutralLight = Color(red: 230/255, green: 230/255, blue: 230/255) // #E6E6E6

    // System-derived (kept centralized here)
    static let separator = Color(uiColor: .separator)

    // Card surface (strict)
    static let cardSurfaceLight = Color(.sRGB, red: 242/255, green: 242/255, blue: 247/255, opacity: 1) // #F2F2F7
    static let cardSurfaceDark  = Color(.sRGB, red: 28/255,  green: 28/255,  blue: 30/255,  opacity: 1) // #1C1C1E

    static func cardSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark ? cardSurfaceDark : cardSurfaceLight
    }

    // Background / Primary (strict, sRGB)
    static let backgroundPrimaryLight = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1) // #FFFFFF
    static let backgroundPrimaryDark  = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1) // #000000

    static func backgroundPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? backgroundPrimaryDark : backgroundPrimaryLight
    }

    // Status colors
    static let statusOk = Color.green
    static let statusWarn = Color.orange
    static let statusDanger = Color.red

    // Opacities & strokes (design tokens)
    static let opacityBorderSubtle: Double = 0.25
    static let opacityBorderDefault: Double = 0.35
    static let opacityDivider: Double = 0.55
    static let opacityPressedFill: Double = 0.08
    static let shadowOpacityFallback: Double = 0.12

    static let strokeWidthHairline: CGFloat = 1
    static let strokeWidthAccent: CGFloat = 2
    static let ringLineWidth: CGFloat = 5

    // Neutral text/border opacities (theme tokens)
    static let opacityNeutralIdleLight: Double = 0.12
    static let opacityNeutralPausedLight: Double = 0.20
    static let opacityNeutralIdleDark: Double = 0.12
    static let opacityNeutralPausedDark: Double = 0.20

    static let opacityLabelIdleLight: Double = 0.45
    static let opacityLabelPausedLight: Double = 0.55
    static let opacityLabelIdleDark: Double = 0.55
    static let opacityLabelPausedDark: Double = 0.70

    // Helpers
    static func borderNeutral(for scheme: ColorScheme, state: ZoneStatus) -> Color {
        switch (scheme, state) {
        case (.light, .paused):
            return Color.primary.opacity(opacityNeutralPausedLight)
        case (.light, _):
            return Color.primary.opacity(opacityNeutralIdleLight)
        case (.dark, .paused):
            return Color.primary.opacity(opacityNeutralPausedDark)
        default:
            return Color.primary.opacity(opacityNeutralIdleDark)
        }
    }

    static func labelNeutral(for scheme: ColorScheme, state: ZoneStatus) -> Color {
        switch (scheme, state) {
        case (.light, .paused):
            return Color.primary.opacity(opacityLabelPausedLight)
        case (.light, _):
            return Color.primary.opacity(opacityLabelIdleLight)
        case (.dark, .paused):
            return Color.primary.opacity(opacityLabelPausedDark)
        default:
            return Color.primary.opacity(opacityLabelIdleDark)
        }
    }

    static func ringTrackStroke() -> Color { separator.opacity(opacityBorderSubtle) }

    static func strokeSeparatorSubtle() -> Color { separator.opacity(opacityBorderSubtle) }
    static func strokeSeparatorDefault() -> Color { separator.opacity(opacityBorderDefault) }
    static func divider() -> Color { separator.opacity(opacityDivider) }
}

private extension View {
    @ViewBuilder
    func preferredColorSchemeIfNeeded(_ scheme: ColorScheme?) -> some View {
        if let scheme {
            self.preferredColorScheme(scheme)
        } else {
            self
        }
    }
}

// MARK: - Domain

enum Zone: String, CaseIterable, Identifiable {
    case lashLeft, lashRight, browLeft, browRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lashLeft:  return "Левая\nресница"
        case .lashRight: return "Правая\nресница"
        case .browLeft:  return "Левая\nбровь"
        case .browRight: return "Правая\nбровь"
        }
    }

    var subtitle: String {
        switch self {
        case .lashLeft, .lashRight: return "Ресницы"
        case .browLeft, .browRight: return "Брови"
        }
    }

    var limitKey: String { "limitSeconds_\(rawValue)" }

    var defaultLimitSeconds: Int {
        switch self {
        case .lashLeft, .lashRight: return 10 * 60
        case .browLeft, .browRight: return 6 * 60
        }
    }

    /// Relative position on face canvas (0...1)
    var faceAnchor: CGPoint {
        switch self {
        case .lashLeft:  return CGPoint(x: 0.32, y: 0.42)
        case .lashRight: return CGPoint(x: 0.68, y: 0.42)
        case .browLeft:  return CGPoint(x: 0.32, y: 0.33)
        case .browRight: return CGPoint(x: 0.68, y: 0.33)
        }
    }
}

struct ZoneStopwatch {
    var elapsedSeconds: Int = 0
    var isRunning: Bool = false

    /// When the timer started (running state). Nil when paused/idle.
    var startedAt: Date? = nil
    /// Snapshot of elapsedSeconds at the moment of start/resume.
    var baseElapsedSeconds: Int = 0

    mutating func reset() {
        elapsedSeconds = 0
        isRunning = false
        startedAt = nil
        baseElapsedSeconds = 0
    }
}

enum ZoneStatus: Equatable {
    case idle
    case paused
    case ok
    case warn
    case danger

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

// MARK: - Settings

struct AppSettings {
    /// Orange turns on at `warnPercent` of limit (0...1).
    var warnPercent: Double = 0.8

    func limitSeconds(for zone: Zone) -> Int {
        let stored = UserDefaults.standard.integer(forKey: zone.limitKey)
        return stored == 0 ? zone.defaultLimitSeconds : stored
    }

    func setLimitSeconds(_ seconds: Int, for zone: Zone) {
        UserDefaults.standard.set(max(60, seconds), forKey: zone.limitKey)
    }

    func status(for zone: Zone, sw: ZoneStopwatch) -> ZoneStatus {
        if sw.elapsedSeconds == 0 && !sw.isRunning { return .idle }
        if !sw.isRunning { return .paused }

        let limit = max(60, limitSeconds(for: zone))
        let warnAt = Int(Double(limit) * warnPercent)

        if sw.elapsedSeconds >= limit { return .danger }
        if sw.elapsedSeconds >= warnAt { return .warn }
        return .ok
    }

    func progress(for zone: Zone, sw: ZoneStopwatch) -> Double {
        let limit = Double(max(60, limitSeconds(for: zone)))
        return min(1.0, Double(sw.elapsedSeconds) / limit)
    }
}


// MARK: - Persistence

private enum PersistKeys {
    static let stopwatchesState = "stopwatchesState_v1"
}

private struct PersistedStopwatch: Codable {
    var elapsedSeconds: Int
    var isRunning: Bool
    var startedAt: Date?
    var baseElapsedSeconds: Int
}

private struct PersistedState: Codable {
    var items: [String: PersistedStopwatch]
}

// MARK: - Store

@MainActor
final class StopwatchesStore: ObservableObject {
    @Published private(set) var items: [Zone: ZoneStopwatch] = {
        var dict: [Zone: ZoneStopwatch] = [:]
        Zone.allCases.forEach { dict[$0] = ZoneStopwatch() }
        return dict
    }()

    private var ticker: AnyCancellable?

    var settingsProvider: () -> AppSettings = { AppSettings() }
    private var lastStatus: [Zone: ZoneStatus] = [:]

    init() {
        loadFromDisk()
        // Проставляем кэш статусов без хаптики при старте/восстановлении
        primeStatusCache(settings: settingsProvider())
        // Догоняем время для running зон и включаем тикер при необходимости
        refreshRunningElapsed(now: Date())
        syncTicker()
    }

    func toggle(_ zone: Zone) {
        guard var sw = items[zone] else { return }

        if sw.isRunning {
            // Pause: фиксируем точное прошедшее время и останавливаем.
            if let startedAt = sw.startedAt {
                let delta = Int(Date().timeIntervalSince(startedAt))
                sw.elapsedSeconds = max(0, sw.baseElapsedSeconds + delta)
            }
            sw.isRunning = false
            sw.startedAt = nil
        } else {
            // Start/Resume: снимок текущего elapsed и стартовая дата.
            sw.isRunning = true
            sw.baseElapsedSeconds = sw.elapsedSeconds
            sw.startedAt = Date()
        }

        items[zone] = sw
        syncTicker()
        primeStatusCache(settings: settingsProvider())
        saveToDisk()
    }

    func reset(_ zone: Zone) {
        guard var sw = items[zone] else { return }
        sw.reset()
        items[zone] = sw
        syncTicker()
        handleStatusTransitions(settings: settingsProvider())
        saveToDisk()
    }

    func resetAll() {
        Zone.allCases.forEach { z in
            var sw = items[z] ?? ZoneStopwatch()
            sw.reset()
            items[z] = sw
        }
        syncTicker()
        handleStatusTransitions(settings: settingsProvider())
        saveToDisk()
    }

    func pauseAll() {
        // Freeze current elapsed for all running timers first.
        refreshRunningElapsed(now: Date())

        for z in Zone.allCases {
            guard var sw = items[z], sw.isRunning else { continue }
            sw.isRunning = false
            sw.startedAt = nil
            sw.baseElapsedSeconds = sw.elapsedSeconds
            items[z] = sw
        }

        syncTicker()
        primeStatusCache(settings: settingsProvider())
        saveToDisk()
    }

    private func syncTicker() {
        let hasRunning = items.values.contains(where: { $0.isRunning })
        if hasRunning {
            startIfNeeded()
        } else {
            stop()
        }
    }

    private func startIfNeeded() {
        guard ticker == nil else { return }

        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self else { return }

                for z in Zone.allCases {
                    guard var sw = self.items[z], sw.isRunning, let startedAt = sw.startedAt else { continue }
                    let delta = Int(now.timeIntervalSince(startedAt))
                    sw.elapsedSeconds = max(0, sw.baseElapsedSeconds + delta)
                    self.items[z] = sw
                }
                self.handleStatusTransitions(settings: self.settingsProvider())
            }
    }

    private func handleStatusTransitions(settings: AppSettings) {
        for z in Zone.allCases {
            let sw = items[z] ?? ZoneStopwatch()

            // Не спамим уведомлениями, пока зона не бежит.
            let newStatus = settings.status(for: z, sw: sw)
            defer { lastStatus[z] = newStatus }

            guard sw.isRunning else { continue }

            let oldStatus = lastStatus[z]
            guard oldStatus != newStatus else { continue }

            if newStatus == .warn {
                Haptics.warning()
            } else if newStatus == .danger {
                Haptics.error()
            }
        }
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: PersistKeys.stopwatchesState) else { return }
        do {
            let decoded = try JSONDecoder().decode(PersistedState.self, from: data)
            var dict: [Zone: ZoneStopwatch] = [:]
            for z in Zone.allCases {
                if let p = decoded.items[z.rawValue] {
                    dict[z] = ZoneStopwatch(
                        elapsedSeconds: max(0, p.elapsedSeconds),
                        isRunning: p.isRunning,
                        startedAt: p.startedAt,
                        baseElapsedSeconds: max(0, p.baseElapsedSeconds)
                    )
                } else {
                    dict[z] = ZoneStopwatch()
                }
            }
            items = dict
        } catch {
            // ignore broken cache
        }
    }

    private func saveToDisk() {
        var payload: [String: PersistedStopwatch] = [:]
        for z in Zone.allCases {
            let sw = items[z] ?? ZoneStopwatch()
            payload[z.rawValue] = PersistedStopwatch(
                elapsedSeconds: sw.elapsedSeconds,
                isRunning: sw.isRunning,
                startedAt: sw.startedAt,
                baseElapsedSeconds: sw.baseElapsedSeconds
            )
        }
        do {
            let data = try JSONEncoder().encode(PersistedState(items: payload))
            UserDefaults.standard.set(data, forKey: PersistKeys.stopwatchesState)
        } catch {
            // ignore
        }
    }

    /// Recompute elapsed for running timers based on wall clock time (handles background / app killed).
    private func refreshRunningElapsed(now: Date = Date()) {
        for z in Zone.allCases {
            guard var sw = items[z], sw.isRunning, let startedAt = sw.startedAt else { continue }
            let delta = Int(now.timeIntervalSince(startedAt))
            sw.elapsedSeconds = max(0, sw.baseElapsedSeconds + delta)
            items[z] = sw
        }
    }

    /// Prime lastStatus cache so restore/refresh doesn't trigger haptics.
    private func primeStatusCache(settings: AppSettings) {
        for z in Zone.allCases {
            let sw = items[z] ?? ZoneStopwatch()
            lastStatus[z] = settings.status(for: z, sw: sw)
        }
    }

    /// Call when app goes inactive/background: freeze elapsed, stop ticker, persist.
    func appWillResignActive() {
        refreshRunningElapsed(now: Date())
        primeStatusCache(settings: settingsProvider())
        stop()
        saveToDisk()
    }

    /// Call when app becomes active: catch up elapsed, restart ticker if needed.
    func appDidBecomeActive() {
        refreshRunningElapsed(now: Date())
        primeStatusCache(settings: settingsProvider())
        syncTicker()
        saveToDisk()
    }

    private func stop() {
        ticker?.cancel()
        ticker = nil
    }
}

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
