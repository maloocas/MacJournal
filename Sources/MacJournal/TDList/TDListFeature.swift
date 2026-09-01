import Foundation

// ============================================================================
//  TDList FEATURE
//  ----------------------------------------------------------------------------
//  Everything in this folder (Sources/MacJournal/TDList/) belongs to the
//  "TD List" feature: the checklist, check-off timestamp tracking, the
//  floating pop-out window, the hourly check-off chart, and the daily-goals
//  card embedded in the TD List views.
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
//       - the 3 `appData.…` assignments inside `load()`
//       - the 3 `tdCheckoffEvents:…` / `checklistItems:…` / `dailyGoals:…`
//         arguments inside the `AppData(...)` call in `save()`
//
//  3. Models/AppConfig.swift — delete the lines tagged `// [TDList]`:
//       - `tdCheckoffTracking` in `AppConfig` (property, init, decode)
//       - `tdCheckoffEvents`, `checklistItems`, `dailyGoals` in `AppData`
//         (properties, init, decode)
//
//  4. MacJournalApp.swift — delete the lines tagged `// [TDList]`:
//       - `case tdList` in the `Tab` enum + its icon arm
//       - `case .tdList: TDListView()` in `tabContent`
//       - the `settingsTDCheckoffTracking` state, the "TD LIST TRACKING"
//         settings toggle block, and its load/save lines
//
//  5. Views/DashboardView.swift — delete the lines tagged `// [TDList]`:
//       - `middleColumn` (the whole column is the TD List widget:
//         header, pop-out button, daily-goals card, checklist)
//       - `emptyChecklistPlaceholder`, `checklistContent`,
//         `dailyGoalsDashboardSection`
//       - `toggleItem` / `deleteItem` and `dashboardDailyGoalText`
//
//  6. Views/DailyLogView.swift — delete the lines tagged `// [TDList]`:
//       - `syncChecklistCounts()` and its call in `loadEntryForDate()`
//         (after removal, today's pro/per counts on the Daily Log form
//         are entered manually — the Entry fields themselves stay)
//
//  7. Views/StatsView.swift — delete the lines tagged `// [TDList]`:
//       - the `tdCheckoffEvents` state, its `onReceive`, the
//         `if store.config.tdCheckoffTracking` block in `refreshChartData()`,
//         and the `HourlyCheckoffChart` in `chartGrid`
//
//  After step 1–7 the app builds without any TD List code. `Entry` keeps
//  its proTotal/proDone/perTotal/perDone fields (shared with the Daily Log
//  form, KPIs, and CSV export); they just stop auto-syncing from the
//  checklist.
// ============================================================================

/// Feature marker: never referenced at runtime. Its only purpose is to make
/// the TD List feature discoverable in Xcode's project navigator and to pin
/// the removal checklist above to a source file.
enum TDListFeature {}
