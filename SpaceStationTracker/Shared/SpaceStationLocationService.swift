//
//  SatelliteService.swift
//  SpaceStationTracker
//
//  Created by Joshua Homann on 10/9/22.
//

import Foundation
import MapKit

actor SpaceStationLocationService {
    func locations(starting date: Date = .now, hourlyIntervals: Int = 10) async throws -> [SpaceStationLocation] {
        let components = Calendar.current.dateComponents([.hour], from: date)
        let adjusted = Calendar.current.date(bySettingHour: components.hour ?? 0, minute: 0, second: 0, of: date) ?? .now
        let intervals = sequence(first: adjusted) {
            Calendar.current.date(byAdding: .hour, value: 1, to: $0)
        }
            .prefix(hourlyIntervals)
            .lazy
            .map { String(describing: $0.timeIntervalSince1970) }

        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "api.wheretheiss.at"
        urlComponents.path = "/v1/satellites/25544/positions"
        urlComponents.queryItems = [
            URLQueryItem(name: "units", value: "kilometers"),
            URLQueryItem(
                name: "timestamps",
                value: intervals.joined(separator: ",")
            )
        ]
        guard let url = urlComponents.url else { throw Error.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let code = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(code) else { throw Error.invalidResponse(response) }
        return try JSONDecoder().decode([SpaceStationLocation].self, from: data)
    }
    func geoTaggedLocations(starting date: Date = .now, hourlyIntervals: Int = 10) async throws -> [TaggedSpaceStationLocation] {
        let locations = try await locations()
        let taggedLocations = try await locations.parallelMap { location in
            let geocoder = CLGeocoder()
            return TaggedSpaceStationLocation(
                spaceStationLocation: location,
                locationName: try await geocoder.reverseGeocodeLocation(
                    .init(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                )
                .first?
                .name ?? "Unknown"
            )
        }
        print(taggedLocations.prettyPrinted)
        return taggedLocations
    }
}

extension Sequence {
    func parallelMap<Transformed>( transform: @escaping (Element) async throws -> Transformed) async throws -> [Transformed] {
        var lookup = [Int: Transformed]()
        let count = (self as? any Collection)?.count
        _ = try await withThrowingTaskGroup(of: (Int, Transformed).self) { group in
            for (index, element) in self.enumerated() {
                group.addTask {
                    (index, try await transform(element))
                }
            }
            for try await item in group {
                lookup[item.0] = item.1
            }
            return []
        }
        var transformed = [Transformed]()
        if let count {
            transformed.reserveCapacity(count)
        }
        return (0..<lookup.count).reduce(into: transformed) { accumulated, next in
            accumulated.append(lookup[next]!)
        }
    }
}

extension SpaceStationLocationService {
    enum Error: Swift.Error {
        case invalidURL
        case invalidResponse(URLResponse)
    }
}

private extension URL {
    var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "com.josh.SpaceStationTracker")!
    }
    var cachedTaggedLocationURL: URL {
        containerURL.appendingPathComponent("TaggedSpaceStationLocation.json")
    }
}

private extension Encodable {
    var prettyPrinted: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? JSONEncoder().encode(self))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }
}
