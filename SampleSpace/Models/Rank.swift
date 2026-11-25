import Foundation

/// Pilot ranks, earned with XP. Thresholds live here and nowhere else, so they are easy to
/// retune as content grows. Sectors 0–2 hold about 2,500 XP with every star, so a full
/// curriculum of ~12 sectors is roughly 10,000 XP; thresholds are pegged to sector milestones.
enum Rank: Int, CaseIterable, Comparable, Sendable {
    case cadet, ensign, lieutenant, commander, captain, principalInvestigator

    var title: String {
        switch self {
        case .cadet: "Cadet"
        case .ensign: "Ensign"
        case .lieutenant: "Lieutenant"
        case .commander: "Commander"
        case .captain: "Captain"
        case .principalInvestigator: "Principal Investigator"
        }
    }

    var minimumXP: Int {
        switch self {
        case .cadet: 0
        case .ensign: 400                    // about the end of the Launch Pad
        case .lieutenant: 2000               // about the end of the Data Frame Docks
        case .commander: 4500                // about the end of the Plot Nebula
        case .captain: 7000                  // about the end of the Means Cluster
        case .principalInvestigator: 9500    // about the end of the Dissertation Dock
        }
    }

    var symbol: String {
        switch self {
        case .cadet: "person.badge.shield.checkmark"
        case .ensign: "chevron.up"
        case .lieutenant: "chevron.up.2"
        case .commander: "star"
        case .captain: "star.circle"
        case .principalInvestigator: "graduationcap.fill"
        }
    }

    var next: Rank? { Rank(rawValue: rawValue + 1) }

    static func forXP(_ xp: Int) -> Rank {
        allCases.last { xp >= $0.minimumXP } ?? .cadet
    }

    /// 0–1 progress from this rank's threshold to the next (1 at the top rank).
    static func progress(xp: Int) -> Double {
        let rank = forXP(xp)
        guard let next = rank.next else { return 1 }
        return Double(xp - rank.minimumXP) / Double(next.minimumXP - rank.minimumXP)
    }

    static func < (a: Rank, b: Rank) -> Bool { a.rawValue < b.rawValue }
}
