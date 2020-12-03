import Foundation
import Utils

public struct AdventOfCodeLeaderboard: Decodable {
    public enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case event
        case members
    }

    public let ownerId: String
    public let event: String
    public let members: [String: Member]

    public var year: Int? { Int(event) }
    public var startDate: Date? { challengeReleaseDate(day: 1) }

    public func challengeReleaseDate(day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = 12
        components.day = day
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: -5 * 3600)
        return Calendar.current.date(from: components)
    }

    public func lastTimeToCompletion(member: Member) -> TimeInterval? {
        challengeReleaseDate(day: member.lastDay)
            .flatMap { release in (member.lastStarTs?.date)
                .map { $0.timeIntervalSince(release) } }
    }

    public struct Member: Decodable {
        public enum CodingKeys: String, CodingKey {
            case stars
            case globalScore = "global_score"
            case localScore = "local_score"
            case lastStarTs = "last_star_ts"
            case id
            case completionDayLevel = "completion_day_level"
            case name
        }

        public let stars: Int
        public let globalScore: Int?
        public let localScore: Int?
        public let lastStarTs: Timestamp? // String or Int
        public let id: String?
        public let completionDayLevel: [String: [String: StarCompletion]]?
        public let name: String?

        public var lastDay: Int { starCompletions.keys.max() ?? 1 }
        public var displayName: String { name ?? "<anonymous user \(id ?? "?")>" }
        public var starCompletions: [Int: [StarCompletion]] {
            Dictionary(uniqueKeysWithValues: completionDayLevel?
                .compactMap { (k, v) in Int(k).map { ($0, v.values.sorted(by: ascendingComparator { $0.getStarTs?.date ?? Date.distantFuture })) } }
                ?? [])
        }
        public var starScores: [StarScore] {
            var res = [StarScore]()
            for completion in starCompletions.flatMap(\.value) {
                if let date = completion.getStarTs?.date ?? res.last?.date {
                    res.append(StarScore(score: (res.last?.score ?? 0) + 1, date: date))
                }
            }
            return res
        }

        public struct StarScore {
            public let score: Int
            public let date: Date

            public var shortlyBefore: StarScore { StarScore(score: score - 1, date: date - 0.0001) }

            public init(score: Int, date: Date) {
                self.score = score
                self.date = date
            }
        }

        public struct StarCompletion: Decodable {
            public enum CodingKeys: String, CodingKey {
                case getStarTs = "get_star_ts"
            }

            public let getStarTs: Timestamp?
        }

        public struct Timestamp: Decodable {
            public let date: Date?

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let raw = try? container.decode(String.self)
                date = raw.flatMap(Double.init).map(Date.init(timeIntervalSince1970:))
            }
        }
    }
}