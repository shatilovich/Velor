import Combine
import Foundation

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

    func appDidBecomeActive() {
        refreshRunningElapsed(now: Date())
        primeStatusCache(settings: settingsProvider())
        syncTicker()
    }

    func appWillResignActive() {
        refreshRunningElapsed(now: Date())
        stop()
        saveToDisk()
    }

    func refreshRunningElapsed(now: Date) {
        for z in Zone.allCases {
            guard var sw = items[z], sw.isRunning, let startedAt = sw.startedAt else { continue }
            let delta = Int(now.timeIntervalSince(startedAt))
            sw.elapsedSeconds = max(0, sw.baseElapsedSeconds + delta)
            items[z] = sw
        }
    }

    func primeStatusCache(settings: AppSettings) {
        for z in Zone.allCases {
            let sw = items[z] ?? ZoneStopwatch()
            lastStatus[z] = settings.status(for: z, sw: sw)
        }
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

    private func stop() {
        ticker?.cancel()
        ticker = nil
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

private extension StopwatchesStore {
    func loadFromDisk() {
        guard
            let data = UserDefaults.standard.data(forKey: PersistKeys.stopwatchesState),
            let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        else { return }

        var restored: [Zone: ZoneStopwatch] = [:]

        for (key, value) in state.items {
            guard let zone = Zone(rawValue: key) else { continue }
            restored[zone] = ZoneStopwatch(
                elapsedSeconds: value.elapsedSeconds,
                isRunning: value.isRunning,
                startedAt: value.startedAt,
                baseElapsedSeconds: value.baseElapsedSeconds
            )
        }

        // Update only known zones; keep defaults for missing ones
        for zone in Zone.allCases {
            if let sw = restored[zone] {
                items[zone] = sw
            }
        }

        // Подстрахуемся, что в данные не попали некорректные значения
        refreshRunningElapsed(now: Date())
        stop()
    }

    func saveToDisk() {
        var snapshot: [String: PersistedStopwatch] = [:]

        for (zone, sw) in items {
            snapshot[zone.rawValue] = PersistedStopwatch(
                elapsedSeconds: sw.elapsedSeconds,
                isRunning: sw.isRunning,
                startedAt: sw.startedAt,
                baseElapsedSeconds: sw.baseElapsedSeconds
            )
        }

        guard let data = try? JSONEncoder().encode(PersistedState(items: snapshot)) else { return }
        UserDefaults.standard.set(data, forKey: PersistKeys.stopwatchesState)
    }
}
