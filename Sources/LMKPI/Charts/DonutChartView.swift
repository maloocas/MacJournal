import SwiftUI

// MARK: - Donut Chart (Monochrome)

struct DonutChartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let values: [(label: String, value: Double, color: Color)]

    private var total: Double { values.reduce(0) { $0 + $1.value } }

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let outerR = min(cx, cy) * 0.85
            let innerR = outerR * 0.55
            var startAngle: Double = -90 // start from top

            for item in values where item.value > 0 {
                let sweep = (item.value / max(total, 1)) * 360.0
                let path = arcPath(cx: cx, cy: cy, outerR: outerR, innerR: innerR,
                                   start: startAngle, sweep: sweep)
                context.fill(path, with: .color(item.color))
                context.stroke(path, with: .color(themeManager.colors.border), lineWidth: 0.5)
                startAngle += sweep
            }

            // draw legend on the right
            var legendY: CGFloat = 20
            for item in values where item.value > 0 {
                let dot = CGRect(x: size.width - 130, y: legendY, width: 8, height: 8)
                context.fill(Path(ellipseIn: dot), with: .color(item.color))

                let pct = total > 0 ? Int(round(item.value / total * 100)) : 0
                let text = "\(item.label) (\(pct)%)"
                context.draw(
                    Text(text).font(.system(size: 9)).foregroundColor(themeManager.colors.textPrimary.opacity(0.8)),
                    at: CGPoint(x: size.width - 115, y: legendY + 4)
                )
                legendY += 16
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
