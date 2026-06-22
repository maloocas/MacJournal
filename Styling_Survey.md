# MacJournal Container/Box Styling Survey

## Overview

Survey of all `.background`, `.overlay`, `.border`, and `.clipShape` calls in Views/, Charts/, and MacJournalApp.swift. The **target pattern** (from DailyLogView.swift's `SectionBox`) is:

```
.background(themeManager.colors.surface)         // Color(white: 0.07)
.overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(themeManager.colors.border, lineWidth: 1))
.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
```

---

## Color Key

| Color Alias         | Where Used                      |
|----------------------|---------------------------------|
| `colors.surface`     | SectionBox, FormField, Journal reflection editor, recent entries, NotesChecklistView sub-views, settings popup |
| `colors.card`        | Most cards, boxes, placeholders, chart containers |
| `colors.background`  | Top-level scroll/root backgrounds |
| `colors.border`      | SectionBox, FormField, main form, journal editor, settings popup |
| `colors.borderFaint` | Most other containers, cards, chart boxes |
| `colors.accent`      | Buttons, active editing states, selected tab items |
| `colors.sidebarBg`   | Sidebar only |

---

## 1. DailyLogView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **SectionBox** | `colors.surface` | `colors.border` stroke | ✅ | 12 |
| **FormField** | `colors.surface` | `colors.border` stroke | ❌ | 12 |
| **Main form VStack** | `colors.card` | `colors.border` stroke | ❌ | 12 |
| **Recent entries** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **Journal text editor** | `colors.surface` | `colors.border` stroke | ❌ | 12 |
| **Submit button** | `colors.accent` | `colors.accent` stroke | ❌ | 12 |
| **Root ScrollView** | `colors.background` | — | — | — |
| "Edit" button | `colors.borderFaint` | — | — | — |
| "DEL" button | `colors.surface` | — | — | — |

**Inconsistency**: FormField and main form VStack have `.background` + `.overlay` but **no `.clipShape`**. They should have it for consistency with SectionBox.

---

## 2. DashboardView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **emptyChecklistPlaceholder** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **checklistContent** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **CompactKpiCard** | `RoundedRect.fill(c.card)` | `c.borderFaint` stroke | ✅ | 12 |
| **EmptyCompactKpiCard** | `RoundedRect.fill(c.card)` | `c.borderFaint` stroke | ✅ | 12 |
| **StreakCard** | `RoundedRect.fill(c.card)` | `c.borderFaint` stroke | ✅ | 12 |
| **ChartBox** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **EmptyChartBox** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Variant: KPI cards use `RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.card)` as background (inline fill) vs. `colors.card` color on other blocks — functionally same but different syntax.

---

## 3. PopOutTDListView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **sectionBlock** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Consistent.

---

## 4. GoalsView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **TextField** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Add button** | `colors.card`/`colors.accent` | `colors.borderFaint` stroke | ✅ | 12 |
| **Due date row** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Editing text field** | `colors.background` | `colors.accent` stroke | ❌ | 12 |
| **goalCard** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **emptyState** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Minor: editing text field uses `colors.accent` border instead of `colors.borderFaint`.

---

## 5. StatsView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **KpiStatCard** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **EmptyTrendBox** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Consistent.

---

## 6. InsightsView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **Guidance paragraph** | `colors.card` | `colors.borderFaint` stroke (cornerRadius: 0!) | ❌ | **0** ⚠️ |
| **Briefing suggestions** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Briefing error box** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **InsightCardView** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

**Anomaly**: Guidance paragraph uses `cornerRadius: 0` — intentionally flat as a text block with accent bar indicator.

---

## 7. JournalView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **JournalCard** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Consistent.

---

## 8. TDListView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **Refresh button** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **Empty items** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Progress overview card** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Auto-sync toggles** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Apply to today button** | `colors.card` | `colors.accent` stroke | ❌ | 12 |

**Inconsistency**: Apply-to-today button has no clipShape.

---

## 9. NotesChecklistView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root** | `colors.background` | — | — | — |
| **Auto-sync toggles** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **ErrorStateView** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **EmptyStateView** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **InitialStateView** | `colors.surface` | `colors.borderFaint` stroke | ✅ | 12 |
| **Apply to today button** | `colors.card` | `colors.accent` stroke | ❌ | 12 |

Note: Sub-views use `colors.surface` for background vs. `colors.card` used elsewhere.

---

## 10. GoogleSignInView.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root ZStack** | `colors.background` (ignoresSafeArea) | — | — | — |
| **App icon** | `colors.accent.opacity(0.08)` | `colors.border` stroke | ❌ | **16** ⚠️ |
| **Sign-in card** | `colors.surface` | `colors.borderFaint` stroke (cornerRadius: 0!) | ❌ | **0** ⚠️ |
| **Sign-in button** | `RoundedRect.fill(colors.accent)` | — | ❌ | 12 |

**Anomalies**: App icon uses cornerRadius 16 (different from standard 12). Sign-in card uses cornerRadius 0 (flat bottom card).

---

## 11. AppLogoView.swift
No background/overlay/clipShape pattern — uses only `.stroke()` on shapes.

## 12. SectionHeader.swift
No container box pattern — uses `.overlay(alignment: .bottom)` for divider line only.

---

## 13. Charts — TrendChartViews.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **GlassLineChart** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **GlassStepChart** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Consistent with card pattern.

## 14. Charts — HourlyCheckoffChart.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Root VStack** | `colors.card` | `colors.border` stroke | ❌ | 12 |

**Inconsistency**: No clipShape, and uses `colors.border` instead of `colors.borderFaint`.

## 15–17. RadarChartView.swift, BarChartView.swift, DonutChartView.swift
No background/overlay/clipShape — pure Canvas/Swift Charts drawing. Wrapped by ChartBox/ChartBoxView in DashboardView.

---

## 18. MacJournalApp.swift

| Block | Background | Overlay | ClipShape | Corner Radius |
|-------|-----------|---------|-----------|---------------|
| **Sidebar** | `colors.sidebarBg` | — | — | — |
| **Sidebar tab items** | `RoundedRect.fill(accent.opacity(0.12))` | `accent.opacity(0.25)` stroke (if selected) | ❌ (not needed — bg IS rounded rect) | 12 |
| **Settings popup container** | `colors.surface` | `colors.border` stroke | ✅ | 12 |
| **LLM API key field** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Export Data button** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **Update Config button** | `colors.accent` | `colors.accent` stroke | ❌ | 12 |
| **settingsField (Double)** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |
| **settingsField (Int)** | `colors.card` | `colors.borderFaint` stroke | ✅ | 12 |

Consistent with card pattern.

---

## Summary of Inconsistencies

1. **Missing `.clipShape` on `.background` + `.overlay` combos:**
   - DailyLogView: FormField (line 415-418), main form VStack (line 197-199), journal editor (line 161-162), submit button
   - TDListView: Apply-to-today button (line 266)
   - NotesChecklistView: Apply-to-today button (line 136-138)
   - HourlyCheckoffChart: Root VStack (line 112-113)
   - MacJournalApp: "Update Configuration" button (line 431-436)

2. **Different border color convention:**
   - `colors.border` used in: SectionBox, FormField, main form, journal editor, settings popup
   - `colors.borderFaint` used in: all other cards/boxes (majority)
   - HourlyCheckoffChart uses `colors.border` while most chart containers use `colors.borderFaint`

3. **Color alias variations in backgrounds:**
   - `colors.surface` vs `colors.card` — these are different colors (surface ≈ 0.07, card ≈ slightly different). Some views mix both.
   - Some blocks use inline `RoundedRectangle(...).fill(c.card)` (DashboardView KPI cards) while others use `.background(c.card)` — functionally equivalent but different syntax.

4. **Non-standard corner radii:**
   - GoogleSignInView app icon: **cornerRadius 16** vs standard 12
   - GoogleSignInView sign-in card: **cornerRadius 0** (intentional flat card)
   - InsightsView guidance paragraph: **cornerRadius 0** (intentional)

5. **Button styling irregularity:**
   - Most action buttons use `.background(colors.accent)` + `.foregroundColor(colors.background)` with optional overlay stroke
   - "Apply to Today"/"Update Config" buttons use `.background(colors.card)` with `.overlay(colors.accent stroke)` — different visual language
