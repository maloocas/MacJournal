import SwiftUI

// MARK: - Radar Chart (Monochrome)

struct RadarChartView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let values: [CGFloat] // 0-100 — one per label
    let labels: [String]
    let maxValue: CGFloat = 100.0

    private var lineColor: Color { themeManager.colors.chartLine }
    private var gridColor: Color { themeManager.colors.chartGrid }
    private var fillColor: Color { themeManager.colors.chartFill }

    var body: some View {
        Canvas { context, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let radius = min(cx, cy) * 0.75
            let count = values.count
            guard count > 2 else { return }

            // --- concentric grid rings (10%, 25%, 50%, 75%, 100%) ---
            for ringFraction: CGFloat in [0.1, 0.25, 0.5, 0.75, 1.0] {
                let r = radius * ringFraction
                var path = Path()
                for i in 0..<count {
                    let angle = angleFor(index: i, count: count)
                    let x = cx + r * sin(angle)
                    let y = cy - r * cos(angle)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
            }

            // --- axes from center to each vertex ---
            for i in 0..<count {
                let angle = angleFor(index: i, count: count)
                let x = cx + radius * sin(angle)
                let y = cy - radius * cos(angle)
                var line = Path()
                line.move(to: CGPoint(x: cx, y: cy))
                line.addLine(to: CGPoint(x: x, y: y))
                context.stroke(line, with: .color(gridColor), lineWidth: 0.5)

                // label
                let labelX = cx + (radius + 16) * sin(angle)
                let labelY = cy - (radius + 16) * cos(angle)
                context.draw(
                    Text(labels[i]).font(.system(size: 8)).foregroundColor(themeManager.colors.textSecondary),
                    at: CGPoint(x: labelX, y: labelY)
                )
            }

            // --- data polygon ---
            var dataPath = Path()
            for i in 0..<count {
                let fraction = min(values[i] / maxValue, 1.0)
                let r = radius * fraction
                let angle = angleFor(index: i, count: count)
                let x = cx + r * sin(angle)
                let y = cy - r * cos(angle)
                if i == 0 { dataPath.move(to: CGPoint(x: x, y: y)) }
                else { dataPath.addLine(to: CGPoint(x: x, y: y)) }
            }
            dataPath.closeSubpath()
            context.fill(dataPath, with: .color(fillColor))
            context.stroke(dataPath, with: .color(lineColor), lineWidth: 1.5)

            // --- data points ---
            for i in 0..<count {
                let fraction = min(values[i] / maxValue, 1.0)
                let r = radius * fraction
                let angle = angleFor(index: i, count: count)
                let x = cx + r * sin(angle)
                let y = cy - r * cos(angle)
                let dot = CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5)
                context.fill(Path(ellipseIn: dot), with: .color(themeManager.colors.dotFill))
                context.stroke(Path(ellipseIn: dot), with: .color(themeManager.colors.dotStroke), lineWidth: 1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func angleFor(index: Int, count: Int) -> CGFloat {
        // start from top (3π/2) moving clockwise
        let slice = 2.0 * CGFloat.pi / CGFloat(count)
        // offset so first label is at top
        // 3π/2 is straight up
        return 3.0 * CGFloat.pi / 2.0 + CGFloat(index) * slice
    }
}
