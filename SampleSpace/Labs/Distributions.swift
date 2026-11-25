import Foundation

/// The distributions the inference labs need: Student's t (central and noncentral), the normal
/// quantile and the chi-square density. Values are checked against R in the tests.
extension Stats {
    // MARK: Normal

    /// Standard normal quantile, Φ⁻¹(p) (R's `qnorm`), by bisection to 1e-12.
    static func normalQuantile(_ p: Double) -> Double {
        guard p > 0 else { return -.infinity }
        guard p < 1 else { return .infinity }
        return invert(normalCDF, p, lo: -40, hi: 40)
    }

    // MARK: Student's t

    /// Regularised incomplete beta function Iₓ(a, b), by Lentz's continued fraction.
    static func incompleteBeta(_ x: Double, _ a: Double, _ b: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        let logFront = lgamma(a + b) - lgamma(a) - lgamma(b) + a * log(x) + b * log(1 - x)
        // The continued fraction converges fast for x < (a + 1) / (a + b + 2); use symmetry otherwise.
        if x > (a + 1) / (a + b + 2) { return 1 - incompleteBeta(1 - x, b, a) }
        let tiny = 1e-300
        var c = 1.0, d = 1 - (a + b) * x / (a + 1)
        if abs(d) < tiny { d = tiny }
        d = 1 / d
        var f = d
        for m in 1...300 {
            let m = Double(m)
            var num = m * (b - m) * x / ((a + 2 * m - 1) * (a + 2 * m))
            d = 1 + num * d; if abs(d) < tiny { d = tiny }
            c = 1 + num / c; if abs(c) < tiny { c = tiny }
            d = 1 / d
            f *= d * c
            num = -(a + m) * (a + b + m) * x / ((a + 2 * m) * (a + 2 * m + 1))
            d = 1 + num * d; if abs(d) < tiny { d = tiny }
            c = 1 + num / c; if abs(c) < tiny { c = tiny }
            d = 1 / d
            let delta = d * c
            f *= delta
            if abs(delta - 1) < 1e-15 { break }
        }
        return exp(logFront) * f / a
    }

    /// P(T ≤ t) for Student's t with `df` degrees of freedom (R's `pt`).
    static func tCDF(_ t: Double, df: Double) -> Double {
        guard t.isFinite else { return t > 0 ? 1 : 0 }
        let tail = 0.5 * incompleteBeta(df / (df + t * t), df / 2, 0.5)
        return t >= 0 ? 1 - tail : tail
    }

    /// The t density (R's `dt`).
    static func tDensity(_ t: Double, df: Double) -> Double {
        exp(lgamma((df + 1) / 2) - lgamma(df / 2) - 0.5 * log(df * .pi) - (df + 1) / 2 * log1p(t * t / df))
    }

    /// The t quantile (R's `qt`).
    static func tQuantile(_ p: Double, df: Double) -> Double {
        guard p > 0 else { return -.infinity }
        guard p < 1 else { return .infinity }
        return invert({ tCDF($0, df: df) }, p, lo: -1e4, hi: 1e4)
    }

    // MARK: Chi-square and noncentral t

    /// Log of the chi-square density with `df` degrees of freedom.
    static func logChiSquareDensity(_ x: Double, df: Double) -> Double {
        guard x > 0 else { return df == 2 ? -log(2) : (df < 2 ? .infinity : -.infinity) }
        return (df / 2 - 1) * log(x) - x / 2 - df / 2 * log(2) - lgamma(df / 2)
    }

    /// Integrates g(s) · f(v) over the chi-square variable v (df degrees of freedom), where
    /// s = √(v/df). The noncentral t is T′ = (Z + δ) / s, so its tail and density are integrals
    /// of normal functions over s. Simpson's rule on √v, which tames the peak near 0 for small df.
    private static func overChiSquare(df: Double, _ g: (Double) -> Double) -> Double {
        let hi = (df + 12 * (2 * df).squareRoot() + 40).squareRoot()
        let steps = 1200
        let h = hi / Double(steps)
        var sum = 0.0
        for i in 0...steps {
            let u = Double(i) * h                       // u = √v, so v = u², dv = 2u du
            let v = u * u
            let weight = i == 0 || i == steps ? 1.0 : (i % 2 == 1 ? 4.0 : 2.0)
            guard u > 0 else { continue }
            let f = exp(logChiSquareDensity(v, df: df)) * 2 * u
            sum += weight * g((v / df).squareRoot()) * f
        }
        return sum * h / 3
    }

    /// P(T′ > c) for a noncentral t with `df` and noncentrality `ncp`
    /// (R's `pt(c, df, ncp, lower.tail = FALSE)`).
    static func noncentralTUpper(_ c: Double, df: Double, ncp: Double) -> Double {
        overChiSquare(df: df) { s in 1 - normalCDF(c * s - ncp) }
    }

    /// The noncentral t density (R's `dt(t, df, ncp)`).
    static func noncentralTDensity(_ t: Double, df: Double, ncp: Double) -> Double {
        overChiSquare(df: df) { s in
            let z = t * s - ncp
            return exp(-0.5 * z * z) / (2 * .pi).squareRoot() * s
        }
    }

    /// Power of a two-sample t-test with n per group and standardised effect d, as R's
    /// `power.t.test(n, delta = d, sd = 1, sig.level = alpha)` computes it (its default
    /// `strict = FALSE` counts only the tail in the direction of the effect).
    static func twoSamplePower(d: Double, n: Double, alpha: Double, twoSided: Bool = true) -> Double {
        let df = 2 * (n - 1)
        let critical = tQuantile(1 - alpha / (twoSided ? 2 : 1), df: df)
        return noncentralTUpper(critical, df: df, ncp: d * (n / 2).squareRoot())
    }

    // MARK: F and chi-square

    /// P(F ≤ f) for the F distribution with `df1` and `df2` degrees of freedom (R's `pf`).
    static func fCDF(_ f: Double, df1: Double, df2: Double) -> Double {
        guard f > 0 else { return 0 }
        guard f.isFinite else { return 1 }
        return incompleteBeta(df1 * f / (df1 * f + df2), df1 / 2, df2 / 2)
    }

    /// P(F > f), computed from the other tail of the beta so tiny p-values keep their precision.
    static func fUpper(_ f: Double, df1: Double, df2: Double) -> Double {
        guard f > 0 else { return 1 }
        guard f.isFinite else { return 0 }
        return incompleteBeta(df2 / (df2 + df1 * f), df2 / 2, df1 / 2)
    }

    /// The F density (R's `df`).
    static func fDensity(_ x: Double, df1: Double, df2: Double) -> Double {
        guard x > 0 else { return df1 == 2 ? 1 : (df1 < 2 ? .infinity : 0) }
        let logD = lgamma((df1 + df2) / 2) - lgamma(df1 / 2) - lgamma(df2 / 2) + df1 / 2 * log(df1 / df2)
            + (df1 / 2 - 1) * log(x) - (df1 + df2) / 2 * log1p(df1 * x / df2)
        return exp(logD)
    }

    /// The F quantile (R's `qf`).
    static func fQuantile(_ p: Double, df1: Double, df2: Double) -> Double {
        guard p > 0 else { return 0 }
        guard p < 1 else { return .infinity }
        return invert({ fCDF($0, df1: df1, df2: df2) }, p, lo: 0, hi: 1e5)
    }

    /// Regularised lower incomplete gamma P(a, x): a series below a + 1, a continued fraction above.
    static func incompleteGammaP(_ a: Double, _ x: Double) -> Double {
        guard x > 0 else { return 0 }
        let logFront = a * log(x) - x - lgamma(a)
        if x < a + 1 {
            var term = 1 / a, sum = term, ap = a
            for _ in 0..<1000 {
                ap += 1
                term *= x / ap
                sum += term
                if abs(term) < abs(sum) * 1e-16 { break }
            }
            return min(sum * exp(logFront), 1)
        }
        return 1 - incompleteGammaQFraction(a, x, logFront: logFront)
    }

    /// Upper tail Q(a, x) = 1 − P(a, x) by Lentz's continued fraction (valid for x ≥ a + 1).
    private static func incompleteGammaQFraction(_ a: Double, _ x: Double, logFront: Double) -> Double {
        let tiny = 1e-300
        var b = x + 1 - a, c = 1 / tiny, d = 1 / b, h = d
        for i in 1...1000 {
            let an = -Double(i) * (Double(i) - a)
            b += 2
            d = an * d + b; if abs(d) < tiny { d = tiny }
            c = b + an / c; if abs(c) < tiny { c = tiny }
            d = 1 / d
            let delta = d * c
            h *= delta
            if abs(delta - 1) < 1e-16 { break }
        }
        return exp(logFront) * h
    }

    /// P(χ² > x) with `df` degrees of freedom (R's `pchisq(x, df, lower.tail = FALSE)`).
    static func chiSquareUpper(_ x: Double, df: Double) -> Double {
        guard x > 0 else { return 1 }
        guard x.isFinite else { return 0 }
        let a = df / 2, half = x / 2
        if half < a + 1 { return 1 - incompleteGammaP(a, half) }
        return incompleteGammaQFraction(a, half, logFront: a * log(half) - half - lgamma(a))
    }

    // MARK: Helpers

    /// Solves f(x) = p for an increasing f by bisection.
    private static func invert(_ f: (Double) -> Double, _ p: Double, lo: Double, hi: Double) -> Double {
        var lo = lo, hi = hi
        for _ in 0..<200 {
            let mid = (lo + hi) / 2
            if f(mid) < p { lo = mid } else { hi = mid }
            if hi - lo < 1e-12 { break }
        }
        return (lo + hi) / 2
    }

    /// A standard normal draw (Box–Muller) from a seeded generator.
    static func normalDraw(_ rng: inout SplitMix64) -> Double {
        let u1 = max(Double(rng.next() >> 11) / Double(1 << 53), 1e-300)
        let u2 = Double(rng.next() >> 11) / Double(1 << 53)
        return (-2 * log(u1)).squareRoot() * cos(2 * .pi * u2)
    }

    /// Pearson's r, with the least-squares slope and intercept of y on x.
    static func correlation(_ x: [Double], _ y: [Double]) -> (r: Double, slope: Double, intercept: Double) {
        guard x.count == y.count, x.count > 1 else { return (.nan, .nan, .nan) }
        let mx = mean(x), my = mean(y)
        var sxy = 0.0, sxx = 0.0, syy = 0.0
        for (a, b) in zip(x, y) {
            sxy += (a - mx) * (b - my)
            sxx += (a - mx) * (a - mx)
            syy += (b - my) * (b - my)
        }
        let slope = sxx > 0 ? sxy / sxx : .nan
        return (sxx > 0 && syy > 0 ? sxy / (sxx * syy).squareRoot() : .nan, slope, my - slope * mx)
    }
}
