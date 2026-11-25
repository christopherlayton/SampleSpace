import SwiftUI

/// A one-shot burst of stars and sparks from the centre, fading out after a couple of seconds.
/// Draws nothing when Reduce Motion is on.
struct ConfettiView: View {
    var count = 90
    var duration: Double = 2.6
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now
    @State private var particles: [Particle] = []

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSince(start)
                Canvas { ctx, size in
                    guard t < duration else { return }
                    let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)
                    for p in particles {
                        let x = origin.x + p.vx * t
                        let y = origin.y + p.vy * t + 260 * t * t   // gravity
                        let fade = max(0, 1 - t / duration)
                        var piece = ctx
                        piece.opacity = fade
                        piece.translateBy(x: x, y: y)
                        piece.rotate(by: .radians(p.spin * t))
                        let rect = CGRect(x: -p.size / 2, y: -p.size / 2, width: p.size, height: p.size)
                        if p.isStar {
                            piece.fill(Self.star(in: rect), with: .color(p.color))
                        } else {
                            piece.fill(Path(roundedRect: rect.insetBy(dx: 0, dy: p.size * 0.3), cornerRadius: 1),
                                       with: .color(p.color))
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear {
                start = .now
                var rng = SystemRandomNumberGenerator()
                particles = (0..<count).map { _ in Particle.random(using: &rng) }
            }
        }
    }

    private struct Particle {
        let vx, vy, spin, size: Double
        let color: Color
        let isStar: Bool

        static func random(using rng: inout SystemRandomNumberGenerator) -> Particle {
            let angle = Double.random(in: 0...(2 * .pi), using: &rng)
            let speed = Double.random(in: 120...460, using: &rng)
            let colors: [Color] = [Theme.gold, Theme.accent, Theme.pass, .white, Color.planet(hue: 0.85)]
            return Particle(vx: cos(angle) * speed, vy: sin(angle) * speed - 180,
                            spin: .random(in: -6...6, using: &rng), size: .random(in: 6...13, using: &rng),
                            color: colors.randomElement(using: &rng)!, isStar: Bool.random(using: &rng))
        }
    }

    static func star(in rect: CGRect) -> Path {
        var path = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = rect.width / 2, inner = outer * 0.45
        for i in 0..<10 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = Double(i) * .pi / 5 - .pi / 2
            let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
