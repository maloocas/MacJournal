import SwiftUI

// MARK: - Donut Chart (labels above the ring)

struct DonutChartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let values: [(label: String, value: Double, color: Color)]

    // Layout constants
    private let topPadding: CGFloat = 8
    private let labelGap: CGFloat = 12
    private let bottomPadding: CGFloat = 8
    private let lineHeight: CGFloat = 18
    private let dotSize: CGFloat = 8
    private let dotTextGap: CGFloat = 6

    private var total: Double { values.reduce(0) { $0 + $1.value } }

    var body: some View {
        Canvas { context, size in
            let nonZero = values.filter { $0.value > 0 }
            guard !nonZero.isEmpty else { return }

            // ── Measure label block ──
            let maxTextWidth: CGFloat = maxLabelWidth(for: nonZero)

            // ── Layout geometry ──
            let totalLabelH = CGFloat(nonZero.count) * lineHeight
            let labelBlockW = dotSize + dotTextGap + maxTextWidth
            let labelBlockX = (size.width - labelBlockW) / 2     // center label block
            let donutTop = topPadding + totalLabelH + labelGap
            let donutAreaH = size.height - donutTop - bottomPadding
            let outerR = min(size.width, donutAreaH) * 0.40
            let innerR = outerR * 0.55
            let cx = size.width / 2
            let cy = donutTop + donutAreaH / 2

            // ── Donut ring ──
            var startAngle: Double = -90
            for item in nonZero {
                let sweep = (item.value / max(total, 1)) * 360.0
                let path = arcPath(cx: cx, cy: cy, outerR: outerR, innerR: innerR,
                                   start: startAngle, sweep: sweep)
                context.fill(path, with: .color(item.color))
                context.stroke(path, with: .color(themeManager.colors.border), lineWidth: 0.5)
                startAngle += sweep
            }

            // ── Labels centered above the donut ──
            var labelY: CGFloat = topPadding + lineHeight / 2
            for item in nonZero {
                // Color dot
                let dotRect = CGRect(x: labelBlockX,
                                     y: labelY - dotSize / 2,
                                     width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(item.color))

                // Label text (left-aligned after the dot; Canvas centers Text so offset by half-width)
                let textX = labelBlockX + dotSize + dotTextGap
                let pct = total > 0 ? Int(round(item.value / total * 100)) : 0
                let text = "\(item.label) \(pct)%"
                let textW = CGFloat(text.count) * 5.5  // estimated pixel width
                context.draw(
                    Text(text)
                        .font(.system(size: 9))
                        .foregroundColor(themeManager.colors.textPrimary.opacity(0.8)),
                    at: CGPoint(x: textX + textW / 2, y: labelY + 3)
                )
                labelY += lineHeight
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Helpers

    /// Estimates pixel width for a 9 pt text string.
    private func maxLabelWidth(for items: [(label: String, value: Double, color: Color)]) -> CGFloat {
        let strings = items.map { item -> String in
            let pct = total > 0 ? Int(round(item.value / total * 100)) : 0
            return "\(item.label) \(pct)%"
        }
        let longest = strings.max(by: { $0.count < $1.count }) ?? ""
        // ~5.5 px per char at 9 pt system font; floor at sane minimum
        return max(CGFloat(longest.count) * 5.5, 40)
    }

    private func arcPath(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat,
                         start: Double, sweep: Double) -> Path {
        var p = Path()
        let startRad = start * .pi / 180
        let endRad = (start + sweep) * .pi / 180

        // outer arc
        p.addArc(center: CGPoint(x: cx, y: cy), radius: outerR,
                 startAngle: .radians(startRad), endAngle: .radians(endRad),
                 clockwise: false)
        // line to inner
        p.addLine(to: CGPoint(x: cx + innerR * cos(endRad), y: cy + innerR * sin(endRad)))
        // inner arc (reverse)
        p.addArc(center: CGPoint(x: cx, y: cy), radius: innerR,
                 startAngle: .radians(endRad), endAngle: .radians(startRad),
                 clockwise: true)
        p.closeSubpath()
        return p
    }
}
