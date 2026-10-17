import Foundation

/// A linear model that learns one example at a time: recursive least squares with exponential
/// forgetting, so last week's habits count for more than last year's. Each example costs O(n²)
/// and the whole model is n + n² numbers, small enough to keep in UserDefaults.
struct DrainModel: Codable, Equatable, Sendable {
    private(set) var weights: [Double]
    /// The inverse information matrix, row-major. Large entries mean "not sure yet": those
    /// weights move quickly on the next example.
    private(set) var covariance: [Double]
    let forgetting: Double
    /// Forgetting divides the covariance every step, so a feature that never varies (Low Power
    /// Mode, for someone who never uses it) would see its entry grow without bound and then
    /// swing wildly the day it does vary. Past this trace, forgetting pauses.
    let traceLimit: Double

    var count: Int { weights.count }

    /// `prior` is where the weights start; `variance` is how far from it they may wander early on.
    init(prior: [Double], variance: Double, forgetting: Double) {
        let n = prior.count
        weights = prior
        covariance = (0..<n * n).map { $0 % (n + 1) == 0 ? variance : 0 }
        self.forgetting = forgetting
        traceLimit = variance * Double(n) * 4
    }

    func predict(_ x: [Double]) -> Double {
        zip(weights, x).reduce(0) { $0 + $1.0 * $1.1 }
    }

    mutating func learn(_ x: [Double], _ y: Double) {
        let n = count
        precondition(x.count == n)
        var px = [Double](repeating: 0, count: n)
        for i in 0..<n {
            for j in 0..<n { px[i] += covariance[i * n + j] * x[j] }
        }
        let denominator = forgetting + zip(x, px).reduce(0) { $0 + $1.0 * $1.1 }
        guard denominator.isFinite, denominator > 0 else { return }
        let gain = px.map { $0 / denominator }
        let error = y - predict(x)
        for i in 0..<n { weights[i] += gain[i] * error }

        let trace = (0..<n).reduce(0) { $0 + covariance[$1 * (n + 1)] }
        let scale = trace < traceLimit ? 1 / forgetting : 1
        for i in 0..<n {
            for j in i..<n {
                // Written symmetrically, so rounding can't drift the matrix out of symmetry.
                let value = (covariance[i * n + j] - gain[i] * px[j]) * scale
                covariance[i * n + j] = value
                covariance[j * n + i] = value
            }
        }
    }
}
