import SwiftUI

// MARK: - Calendar Tab View

struct CalendarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var googleAuth: GoogleAuthManager
    @EnvironmentObject var servicesManager: GoogleServicesManager
    @State private var selectedDate: Date = Date()
    @State private var isEnabling: Bool = false
    @State private var isSigningIn: Bool = false
    @State private var enableError: String?
    @State private var signInError: String?

    private var calendarService: GoogleCalendarService? {
        servicesManager.service(named: "calendar") as? GoogleCalendarService
    }

    var body: some View {
        let cal = Calendar.current

        if let service = calendarService, service.isEnabled {
            enabledView(service: service, cal: cal)
        } else if calendarService != nil {
            if googleAuth.isAuthenticated {
                enablePromptView
            } else {
                signInPromptView
            }
        } else {
            notRegisteredView
        }
    }

    // MARK: - Enabled: Full Calendar UI

    private func enabledView(service: GoogleCalendarService, cal: Calendar) -> some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack(spacing: 0) {
                Button(action: { shiftMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString(for: selectedDate))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .textCase(.uppercase)
                    .tracking(2)

                Spacer()

                Button(action: { shiftMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.colors.textSecondary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            themeManager.colors.sectionDivider.frame(height: 1)
                .padding(.horizontal, 20)

            // Month grid
            monthGrid(cal: cal)

            themeManager.colors.borderFaint.frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // Events for selected day
            eventsList(for: selectedDate, service: service)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.colors.background)
        .onAppear {
            fetchEvents(service: service)
        }
        .onChange(of: selectedDate) { _ in
            fetchEvents(service: service)
        }
    }

    // MARK: - Month Grid

    private func monthGrid(cal: Calendar) -> some View {
        let days = daysInMonthGrid(for: selectedDate, cal: cal)

        return VStack(spacing: 0) {
            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)

            // Week rows
            ForEach(0..<6) { week in
                HStack(spacing: 0) {
                    ForEach(0..<7) { col in
                        let index = week * 7 + col
                        if index < days.count {
                            let day = days[index]
                            dayCell(day: day, cal: cal)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func dayCell(day: CalendarDay, cal: Calendar) -> some View {
        let isToday = cal.isDateInToday(day.date)
        let isSelected = cal.isDate(day.date, inSameDayAs: selectedDate)
        let isCurrentMonth = cal.isDate(day.date, equalTo: selectedDate, toGranularity: .month)
        let hasEvents = day.events > 0

        return Button(action: { selectedDate = day.date }) {
            VStack(spacing: 4) {
                ZStack {
                    // Selection highlight
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(themeManager.colors.accent.opacity(0.12))
                            .frame(width: 32, height: 32)
                    }

                    Text("\(cal.component(.day, from: day.date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .regular))
                        .foregroundColor(
                            isCurrentMonth
                                ? (isSelected ? themeManager.colors.accent : themeManager.colors.textPrimary)
                                : themeManager.colors.textMuted
                        )
                }

                // Event dot
                if hasEvents {
                    Circle()
                        .fill(themeManager.colors.accent.opacity(isCurrentMonth ? 0.6 : 0.2))
                        .frame(width: 4, height: 4)
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Events List

    private func eventsList(for date: Date, service: GoogleCalendarService) -> some View {
        let cal = Calendar.current
        let dayEvents = service.events.filter { event in
            cal.isDate(event.startDate, inSameDayAs: date)
        }

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Date header
                Text(formattedDate(date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.colors.textPrimary)
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                if dayEvents.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Text("No events")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeManager.colors.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    ForEach(dayEvents) { event in
                        eventCard(event)
                    }
                }

                // Refresh button — always visible
                Button(action: {
                    fetchEvents(service: service)
                }) {
                    HStack(spacing: 8) {
                        if service.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                        }
                        Text("Refresh")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(themeManager.colors.textMuted)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if let err = service.lastError {
                    Text(err)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeManager.colors.textMuted)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func eventCard(_ event: GoogleCalendarEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Time
            if !event.isAllDay {
                let startFmt = timeFormatter.string(from: event.startDate)
                let endFmt = timeFormatter.string(from: event.endDate)
                Text("\(startFmt) – \(endFmt)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
            } else {
                Text("All Day")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(themeManager.colors.textMuted)
            }

            // Title
            Text(event.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeManager.colors.textPrimary)

            // Location
            if let location = event.location, !location.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 9))
                    Text(location)
                        .font(.system(size: 11))
                }
                .foregroundColor(themeManager.colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(themeManager.colors.borderFaint, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Sign-In Prompt (shown when not authenticated)

    private var signInPromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.colors.accent.opacity(0.06))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.colors.borderFaint, lineWidth: 1)
                    )

                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.colors.accent)
            }

            VStack(spacing: 8) {
                Text("Google Calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.colors.textPrimary)

                Text("Sign in with Google to view your calendar events")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textSecondary)
            }

            Button(action: startSignInThenEnable) {
                HStack(spacing: 10) {
                    if isSigningIn {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(themeManager.colors.background)
                    }
                    Text(isSigningIn ? "Signing in..." : "Sign in with Google")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(themeManager.colors.background)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(themeManager.colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(isSigningIn)

            if let error = signInError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textMuted)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.colors.background)
    }

    // MARK: - Enable Prompt

    private var enablePromptView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.colors.accent.opacity(0.06))
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.colors.borderFaint, lineWidth: 1)
                    )

                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.colors.accent)
            }

            VStack(spacing: 8) {
                Text("Google Calendar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.colors.textPrimary)

                Text("View your events inside LM KPI")
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.colors.textSecondary)
            }

            Button(action: enableService) {
                HStack(spacing: 10) {
                    if isEnabling {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(themeManager.colors.background)
                    }
                    Text(isEnabling ? "Enabling..." : "Enable Calendar")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(themeManager.colors.background)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(themeManager.colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(isEnabling)

            if let error = enableError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.colors.textMuted)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.colors.background)
    }

    // MARK: - Not Registered

    private var notRegisteredView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Calendar service not available")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.colors.textMuted)
            Text("The Calendar integration has not been registered.")
                .font(.system(size: 12))
                .foregroundColor(themeManager.colors.textMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.colors.background)
    }

    // MARK: - Actions

    private func fetchEvents(service: GoogleCalendarService) {
        Task {
            do {
                try await service.fetchEventsForMonth(containing: selectedDate)
            } catch {
                service.lastError = error.localizedDescription
            }
        }
    }

    private func enableService() {
        isEnabling = true
        enableError = nil
        Task {
            do {
                try await servicesManager.enable("calendar")
            } catch {
                enableError = error.localizedDescription
            }
            isEnabling = false
        }
    }

    private func startSignInThenEnable() {
        isSigningIn = true
        signInError = nil
        Task {
            do {
                // Sign in with base scopes
                let scopes = [
                    GoogleScope.userinfoEmail.rawValue,
                    GoogleScope.userinfoProfile.rawValue
                ]
                try await googleAuth.signIn(with: scopes)
                // Configure services and enable calendar
                await servicesManager.configureAll(with: googleAuth)
                try await servicesManager.enable("calendar")
            } catch {
                signInError = error.localizedDescription
            }
            isSigningIn = false
        }
    }

    private func shiftMonth(by delta: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: delta, to: selectedDate) {
            selectedDate = newDate
        }
    }

    // MARK: - Helpers

    private var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private func monthYearString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: date)
    }

    private func daysInMonthGrid(for date: Date, cal: Calendar) -> [CalendarDay] {
        guard let monthInterval = cal.dateInterval(of: .month, for: date) else {
            return []
        }
        let firstDay = monthInterval.start
        let weekday = cal.component(.weekday, from: firstDay) // 1=Sun, 7=Sat
        let leadingDays = weekday - 1

        guard let startDate = cal.date(byAdding: .day, value: -leadingDays, to: firstDay) else {
            return []
        }

        let service = calendarService
        let events = service?.events ?? []

        var days: [CalendarDay] = []
        for i in 0..<42 {
            guard let day = cal.date(byAdding: .day, value: i, to: startDate) else { continue }
            let count = events.filter { cal.isDate($0.startDate, inSameDayAs: day) }.count
            days.append(CalendarDay(date: day, events: count))
        }
        return days
    }
}

// MARK: - Supporting Types

private struct CalendarDay {
    let date: Date
    let events: Int
}
