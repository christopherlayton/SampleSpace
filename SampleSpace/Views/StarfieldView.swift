import SwiftUI

/// Animated background: drifting, twinkling stars over two soft nebulae.
/// Pauses its animation when the system "Reduce motion" setting is on.
struct StarfieldView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let stars = Star.generate(count: 280, seed: 7)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bounds = CGRect(origin: .zero, size: size)
                ctx.fill(Path(bounds), with: .linearGradient(
                    Gradient(colors: [Theme.spaceTop, Theme.spaceBottom]),
                    startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)))

                drawNebula(&ctx, size: size, center: CGPoint(x: 0.25, y: 0.3), radius: 0.45,
                           color: Theme.nebulaViolet, t: t)
                drawNebula(&ctx, size: size, center: CGPoint(x: 0.8, y: 0.75), radius: 0.4,
                           color: Theme.nebulaTeal, t: t + 40)

                for star in stars {
                    var x = star.x + t * star.drift
                    x -= x.rounded(.down)
                    let twinkle = 0.65 + 0.35 * sin(t * star.twinkleSpeed + star.phase)
                    let rect = CGRect(x: x * size.width, y: star.y * size.height,
                                      width: star.size, height: star.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(star.tint.opacity(star.brightness * twinkle)))
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func drawNebula(_ ctx: inout GraphicsContext, size: CGSize, center: CGPoint,
                            radius: Double, color: Color, t: Double) {
        let breathe = 1 + 0.04 * sin(t * 0.15)
        let r = radius * max(size.width, size.height) * breathe
        let c = CGPoint(x: center.x * size.width, y: center.y * size.height)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.28), color.opacity(0)]),
                                       center: c, startRadius: 0, endRadius: r))
    }
}

private struct Star {
    let x: Double, y: Double
    let size: Double
    let brightness: Double
    let drift: Double
    let twinkleSpeed: Double
    let phase: Double
    let tint: Color

    static func generate(count: Int, seed: UInt64) -> [Star] {
        var rng = SplitMix64(seed: seed)
        let tints: [Color] = [.white, .white, .white, Color(red: 0.75, green: 0.85, blue: 1), Color(red: 1, green: 0.9, blue: 0.75)]
        return (0..<count).map { _ in
            let depth = Double.random(in: 0...1, using: &rng)   // 0 = far, 1 = near
            return Star(
                x: .random(in: 0...1, using: &rng),
                y: .random(in: 0...1, using: &rng),
                size: 0.8 + depth * 2.0,
                brightness: 0.35 + depth * 0.6,
                drift: 0.0008 + depth * 0.003,
                twinkleSpeed: .random(in: 0.6...2.4, using: &rng),
                phase: .random(in: 0...(2 * .pi), using: &rng),
                tint: tints[Int.random(in: 0..<tints.count, using: &rng)])
        }
    }
}

/// Small deterministic RNG: the same star layout every launch, and repeatable lab draws in tests.
struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
