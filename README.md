# MacJournal

A native macOS journaling and personal metrics tracking application built for Apple Silicon. MacJournal combines structured daily KPI logging, Apple Notes todo list integration, trend visualization, and AI-powered insights into a single performant, dark-mode-native experience.

## Features

### Daily KPI Logging
Track recurring daily metrics with a structured entry system:

- **Sleep tracking** — hours logged with configurable target ranges
- **Diet logging** — per-meal categorization (Healthy, Fancy, Standard, Junk, Skipped)
- **Task completion** — split into Professional and Personal & Academic categories
- **Reading progress** — pages read per day with configurable targets
- **Meditation tracking** — daily check-in
- **Social time** — minutes spent socializing (affects efficiency scoring)
- **Auto-computed KPIs** — Tasks Done Index (TDI), Efficiency Score, Focus Ratio, Sleep Metric, Reading Score, and per-category execution rates

### Todo List (TD List)
Sync checklists directly from Apple Notes:

- **Apple Notes integration** — reads `[x]` / `[ ]` markers from your TD List note
- **Dual sections** — Professional and Personal & Academic, each with its own progress tracking
- **Inline editing** — tap to toggle, pencil to edit, trash to delete
- **Auto-sync** — optionally refresh every 5 minutes
- **Dual progress views** — progress rings and sync-section progress bars
- **Pop-out window** — compact floating TD List view for quick access

### Charts & Trends
Visualize your data over time:

- **Bar chart** — weekly/monthly trends (TDI, Efficiency, Sleep, Reading, etc.)
- **Donut chart** — diet composition breakdown
- **Radar chart** — multi-metric daily overview
- **Hourly checkoff chart** — time-of-day task completion distribution
- **Trend chart** — multi-week smoothed trendlines

### AI Morning Briefing
Powered by DeepSeek LLM, generates a daily summary with personalized suggestions based on your recent data. Configurable model selection and API key in Settings.

### Goals
Set and track progress toward personal targets. Visual progress bars for each active goal.

### Data Management
- **Auto-save** — entries persist immediately to local JSON storage with atomic writes
- **Import/Export** — CSV export, JSON import/export, legacy web app import
- **Auto-backup** — timestamped backups on every write
- **Checkoff timestamp tracking** — optional recording of when items are checked/unchecked

## Installation

### Prerequisites
- macOS running on Apple Silicon (M1, M2, M3, or later)
- Xcode command-line tools (`xcode-select --install`)

### Build from Source

```bash
git clone https://github.com/maloocas/MacJournal.git
cd MacJournal
swift build -c release
bash build_app.sh
```

The built app will be at `MacJournal DEV BUILD.app`.

### Migrating from the Web App
If you were using the earlier web-based version:

1. Open `MacJournal.html` in Safari
2. Open the app's bundled `export_helper.html` (inside the .app bundle at `Contents/Resources/export_helper.html`)
3. Click Export & Download Data
4. In the native app, go to **File > Import from Web App (JSON)...** (Cmd+Shift+I)

## Usage

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Cmd+Shift+I | Import from web app JSON |
| Cmd+Shift+E | Export all data as JSON |

### Settings
Access the settings panel via the gear icon in the sidebar. Configure:

- **Reading Target** — daily page goal
- **Social Weight** — penalty multiplier for social time vs productivity
- **Sleep Optimization** — target min/max hours and penalty threshold
- **TD List Tracking** — enable/disable checkoff timestamp recording
- **Morning Briefing** — toggle AI briefings, select model, enter DeepSeek API key

### Apple Notes Setup
1. Create a note titled **"TD List"** (or configure the title in code)
2. Add checklist items using `[x]` for completed and `[ ]` for pending
3. Separate sections with a heading for "Professional" and "Personal & Academic"
4. The app syncs changes both ways — toggling in the app updates the note, and vice versa

## Tech Stack

- **Language:** Swift 5.9
- **Framework:** SwiftUI (macOS 13+)
- **Storage:** Local JSON with atomic file writes
- **AI:** DeepSeek LLM API (configurable)
- **Build:** Swift Package Manager (no external dependencies)

## License

MIT
