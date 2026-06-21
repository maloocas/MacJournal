import SwiftUI

// MARK: - Minimal Monochrome App Logo (circle + notebook)

struct AppLogoView: View {
    let size: CGFloat

    private var strokeWidth: CGFloat { size * 0.048 }
    private var nbStrokeWidth: CGFloat { size * 0.028 }

    var body: some View {
        ZStack {
            // Circle outline
            Circle()
                .stroke(style: StrokeStyle(lineWidth: strokeWidth))

            // Notebook icon
            notebookPath
                .stroke(style: StrokeStyle(lineWidth: nbStrokeWidth))
        }
        .frame(width: size, height: size)
    }

    private var notebookPath: Path {
        let w = size * 0.48
        let h = w * 1.35
        let cr = w * 0.08
        let spine = w * 0.18
        let halfW = w / 2
        let halfH = h / 2

        let left = -halfW + w * 0.28
        let right = halfW - w * 0.15
        let yStart = -h * 0.22
        let yEnd = h * 0.35
        let lineCount = 7

        var path = Path()

        // Rounded rect body
        let rect = CGRect(x: -halfW, y: -halfH, width: w, height: h)
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cr, height: cr))

        // Spine line
        let spineX = -halfW + spine
        path.move(to: CGPoint(x: spineX, y: -halfH + cr))
        path.addLine(to: CGPoint(x: spineX, y: halfH - cr))

        // Page lines
        for i in 0..<lineCount {
            let y = yStart + CGFloat(i) * (yEnd - yStart) / CGFloat(lineCount - 1)
            let r = (i == lineCount - 1) ? right - w * 0.28 : right
            path.move(to: CGPoint(x: left, y: y))
            path.addLine(to: CGPoint(x: r, y: y))
        }

        return path
    }
}
