import Foundation

// ============================================================================
//  TDList FEATURE
//  ----------------------------------------------------------------------------
//  Everything in this folder (Sources/MacJournal/TDList/) belongs to the
//  "TD List" feature: the P0–P4 and Upcoming checklist, check-off timestamp
//  tracking, the floating pop-out window, its daily-goals card, and legacy
//  data migration.
//
//  Every reference to this feature OUTSIDE this folder is tagged with a
//  `// [TDList]` comment. To remove the feature entirely:
//
//  ============================================================================
//  REMOVAL CHECKLIST
//  ============================================================================
//  1. Delete this folder:  rm -rf Sources/MacJournal/TDList
//
//  2. Services/DataStore.swift — delete the lines tagged `// [TDList]`:
//       - the `@Published var tdCheckoffEvents` / `checklistItems` /
//         `dailyGoals` properties (near the top of the class)
//       - the checklist mapping from legacy `dailyRecurringTasks` in `load()`
//       - the 3 TD List arguments in the `AppData(...)` call in `save()`
//
//  3. Models/AppConfig.swift — delete the lines tagged `// [TDList]`:
//       - `tdCheckoffTracking` in `AppConfig` (property, init, decode)
//       - `tdCheckoffEvents`, `checklistItems`, and `dailyGoals` as app data
//         fields; `dailyRecurringTasks` is the legacy migration key
//
//  4. MacJournalApp.swift — delete the lines tagged `// [TDList]`:
//       - `case tdList` in the `Tab` enum + its icon arm
//       - `case .tdList: TDListView()` in `tabContent`
//       - the `settingsTDCheckoffTracking` state, the "TD LIST TRACKING"
//         settings toggle block, and its load/save lines
//
//  5. Views/DashboardView.swift — delete the lines tagged `// [TDList]`:
//       - `middleColumn` (TD List header, pop-out button, P0–P4 and Upcoming checklist)
//       - `checklistContent`, `toggleItem`, and `deleteItem`
//
//  6. Views/DailyLogView.swift — remove its automatic TD List task counts
//     and the combined task fields from Entry when removing the feature.
//
//  7. Views/StatsView.swift — delete the lines tagged `// [TDList]`:
//       - the `tdCheckoffEvents` state, its `onReceive`, the
//         `if store.config.tdCheckoffTracking` block in `refreshChartData()`,
//         and the `HourlyCheckoffChart` in `chartGrid`
//
//  After step 1–7 the app builds without any TD List code. `Entry` keeps
//  totalItems/completedItems for the Daily Log, KPIs, and CSV export; they
//  just stop auto-syncing from the checklist.
// ============================================================================

/// Feature marker: never referenced at runtime. Its only purpose is to make
/// the TD List feature discoverable in Xcode's project navigator and to pin
/// the removal checklist above to a source file.
enum TDListFeature {}
