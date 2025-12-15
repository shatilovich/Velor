import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var store = StopwatchesStore()
    @State private var settings = AppSettings()
    
    @State private var showMenu = false
    @State private var appTheme: String = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
    @State private var warnPercent: Double = {
        let v = UserDefaults.standard.double(forKey: "warnPercent")
        return v == 0 ? 0.8 : v
    }()
    
    private var effectiveColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundPrimary(for: (effectiveColorScheme ?? .light))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ZoneGrid(
                            settings: settings,
                            items: store.items,
                            onTapZone: { zone in
                                Haptics.tap()
                                store.toggle(zone)
                            }
                        )
                        
                        HStack(spacing: 12) {
                            Button {
                                Haptics.resetTap()
                                store.resetAll()
                            } label: {
                                Label("Сбросить все", systemImage: "arrow.counterclockwise")
                            }
                            
                            Button {
                                Haptics.pause()
                                store.pauseAll()
                            } label: {
                                Label("Пауза", systemImage: "pause.fill")
                            }
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal, 2)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Velor")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showMenu = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showMenu) {
            MenuView(
                warnPercent: Binding(
                    get: { warnPercent },
                    set: { newValue in
                        warnPercent = newValue
                        UserDefaults.standard.set(newValue, forKey: "warnPercent")
                        settings.warnPercent = newValue
                        store.settingsProvider = { settings }
                    }
                ),
                appTheme: Binding(
                    get: { appTheme },
                    set: { newValue in
                        appTheme = newValue
                        UserDefaults.standard.set(newValue, forKey: "appTheme")
                    }
                ),
                getLimitSeconds: { zone in
                    settings.limitSeconds(for: zone)
                },
                setLimitMinutes: { zone, minutes in
                    let seconds = max(60, minutes * 60)
                    settings.setLimitSeconds(seconds, for: zone)
                    store.settingsProvider = { settings }
                }
            )
        }
        .preferredColorScheme(effectiveColorScheme)
        .onAppear {
            // Initialize settings into the store
            settings.warnPercent = warnPercent
            store.settingsProvider = { settings }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .inactive, .background:
                store.appWillResignActive()
            case .active:
                store.appDidBecomeActive()
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
