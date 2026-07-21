# MacJournal

<p align="center">
  <img src="Resources/MacJournal_Icon.png" width="128" alt="MacJournal icon" />
</p>

<p align="center">
  <strong>A native macOS journaling and personal metrics tracking application</strong><br>
  Built for Apple Silicon. Dark mode native. Zero external dependencies.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-8CBF8C" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9-8CBF8C" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-8CBF8C" alt="MIT License">
  <img src="https://img.shields.io/badge/Apple%20Silicon-native-8CBF8C" alt="Apple Silicon Native">
</p>

---

## 🤖 Agentic Installation Guide

For AI coding agents (Claude Code, Cursor, Copilot, etc.) to install MacJournal automatically:

```bash
# 1. Download the DMG from the latest GitHub release
curl -L -o /tmp/MacJournal.dmg \
  https://github.com/maloocas/MacJournal/releases/download/v1.0.5/MacJournal.dmg

# 2. Mount the disk image
hdiutil attach /tmp/MacJournal.dmg -nobrowse -mountpoint /tmp/MacJournal

# 3. Copy to Applications
cp -R "/tmp/MacJournal/MacJournal.app" /Applications/

# 4. Detach and clean up
hdiutil detach /tmp/MacJournal
rm /tmp/MacJournal.dmg
```

**Requirements:** macOS 13+, Apple Silicon.

---

## Features

### 📊 Daily KPI Logging
Track recurring daily metrics through a structured entry system:

- **Sleep tracking** — hours logged with configurable target ranges
- **Diet logging** — per-meal categorization (Healthy, Fancy, Standard, Junk, Skipped)
- **Task completion** — split into Professional and Personal & Academic categories
- **Reading progress** — pages read per day with configurable targets
- **Meditation tracking** — daily check-in toggle
- **Social time** — minutes spent socializing (affects efficiency scoring)
- **Auto-computed KPIs** — Tasks Done Index (TDI), Efficiency Score, Focus Ratio, Sleep Metric, Reading Score, and per-category execution rates

### 📋 TD List
Daily task management with local checklists:

- **Dual sections** — Professional and Personal & Academic, each with independent progress tracking
- **Inline editing** — tap to toggle, pencil to edit, trash to delete
- **Dual progress views** — progress rings and section progress bars
- **Pop-out window** — compact floating TD List view

### 💳 Subscription Tracking
Track recurring subscriptions and expenses:

- **Name, amount, billing cycle** — monthly, yearly, weekly, or custom
- **Next payment date** — never miss a renewal
- **Inline editing** — edit or delete subscriptions
- **Persistent storage** — synced with your journal data

### 📈 Charts & Trends
Visualize your data over multiple time horizons:

- **Bar chart** — weekly/monthly trends (TDI, Efficiency, Sleep, Reading, etc.)
- **Donut chart** — diet composition breakdown
- **Radar chart** — multi-metric daily overview snapshot
- **Hourly checkoff chart** — time-of-day task completion distribution, integrated into the chart grid
- **Configurable chart window** — set the rolling time frame (in days) via Settings
- **Trend chart** — multi-week smoothed trendlines for long-term pattern recognition

### 🧠 AI Morning Briefing
Powered by an LLM backend (DeepSeek by default, configurable), generates a daily summary with personalized suggestions based on your recent data. Configure model selection and API key in Settings.

### 🎯 Goals
Set and track progress toward personal targets. Each active goal displays a visual progress bar driven by your logged data.

### 🎯 Trap Shooting
Log and analyze trap shooting rounds with detailed performance tracking:

- **Round logging** — log each round with score (0–25), date, time of day, weather conditions, wind speed, temperature, squad size, gun, ammo, location, and competition flag
- **Stat cards** — average score, best round, hit rate, total rounds, and best 20+ streak tracking
- **Analytics charts** — score trend over time, score distribution histogram, 7-round rolling average, and weather impact analysis comparing average scores by condition
- **AI coaching analysis** — generates an LLM-powered breakdown with specific suggestions and encouragement based on your 30/90-day data, weather patterns, and performance streaks
- **History** — searchable, filterable round history with inline edit and delete

### 💾 Data Management
- **Auto-save** — entries persist immediately to local JSON storage with atomic writes
- **Import/Export** — CSV export, JSON import/export, legacy web app import
- **Auto-backup** — timestamped backups created on every write
- **Checkoff timestamp tracking** — optional recording of when items are checked or unchecked

---

## Screenshots

> Screenshots coming soon. In the meantime, you can build and run the app to see it in action.

---

## Installation

### Option 1: Download the DMG (Recommended)

[Download the latest release](https://github.com/maloocas/MacJournal/releases/latest) — download `MacJournal.dmg`, open it, and drag the app to your Applications folder.

**Requirements:**
- macOS 13+ (Ventura or later)
- Apple Silicon (M1, M2, M3, M4, or later)

### Option 2: Build from Source

```bash
# Prerequisites: Xcode command-line tools
xcode-select --install

# Clone and build
git clone https://github.com/maloocas/MacJournal.git
cd MacJournal
swift build -c release
bash build_app.sh
```

The built app will be at `MacJournal.app` in the project directory.

---

## Usage

### Quick Start

1. Launch MacJournal
2. Start logging in the **Daily Log** tab — entries auto-save
3. View your metrics on the **Dashboard** with computed KPIs
4. Explore **Trends** and **Insights** as your data accumulates

### Keyboard Shortcuts

| Shortcut       | Action                        |
|----------------|-------------------------------|
| `Cmd+Shift+I`  | Import from web app JSON      |
| `Cmd+Shift+E`  | Export all data as JSON       |

### Settings

Access the settings panel via the gear icon in the sidebar. Configuration options:

| Setting             | Description                                                  |
|---------------------|--------------------------------------------------------------|
| **Reading Target**  | Daily page goal                                              |
| **Social Weight**   | Penalty multiplier for social time vs productivity           |
| **Sleep Optimization** | Target min/max hours and penalty threshold               |
| **Chart Window**    | Rolling day range for stats trend charts                    |
| **TD List Tracking** | Enable/disable checkoff timestamp recording                |
| **Morning Briefing** | Toggle AI briefings, select model, enter API key           |

### Migrating from the Web App

If you were using the earlier web-based version of MacJournal:

1. Open `MacJournal.html` in Safari
2. Open the app's bundled `export_helper.html` (inside the `.app` bundle at `Contents/Resources/export_helper.html`)
3. Click **Export & Download Data**
4. In the native app, go to **File > Import from Web App (JSON)...** (`Cmd+Shift+I`)

---

## Tech Stack

| Component     | Technology                              |
|---------------|-----------------------------------------|
| Language      | Swift 5.9                               |
| Framework     | SwiftUI (macOS 13+)                     |
| Storage       | Local JSON with atomic file writes      |
| AI            | DeepSeek LLM API (configurable)         |
| Build         | Swift Package Manager                   |
| Dependencies  | Zero external dependencies              |

---

## License

MIT — see [LICENSE](LICENSE) for details.
