import Foundation
import AppKit

// MARK: - Screen Usage Tracker

@MainActor
class ScreenTrackerService: ObservableObject {
    private let store: DataStore
    private var observers: [NSObjectProtocol] = []

    init(store: DataStore) {
        self.store = store
    }

    func start() {
        let nc = NSWorkspace.shared.notificationCenter

        observers.append(
            nc.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.screenDidWake()
                }
            }
        )

        observers.append(
            nc.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.screenDidSleep()
                }
            }
        )

        // If no open session (last one has an end date or list is empty), start one now
        if store.screenUsageSessions.last?.end != nil || store.screenUsageSessions.isEmpty {
            beginSession()
        }
    }

    func stop() {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }

    private func screenDidWake() {
        if let last = store.screenUsageSessions.last, last.end == nil {
            return // already tracking
        }
        beginSession()
    }

    private func screenDidSleep() {
        closeOpenSession()
    }

    private func beginSession() {
        let session = ScreenUsageSession(start: Date(), end: nil)
        store.screenUsageSessions.append(session)
        store.save()
    }

    private func closeOpenSession() {
        guard let idx = store.screenUsageSessions.lastIndex(where: { $0.end == nil }) else { return }
        store.screenUsageSessions[idx].end = Date()
        store.save()
    }
}
