//
//  MKMapSnapShotter+Async.swift
//  SpaceStationTracker
//
//  Created by Joshua Homann on 11/24/22.
//

import MapKit

extension MKMapSnapshotter {
    static func makeSnapShot(
        coordinate: CLLocationCoordinate2D,
        span: MKCoordinateSpan,
        size: CGSize
    ) async throws -> MKMapSnapshotter.Snapshot {
        let options = MKMapSnapshotter.Options()
        options.region = .init(center: coordinate, span: span)
        options.size = size
        options.traitCollection = .init(traitsFrom: [
            .init(displayScale: UITraitCollection.current.displayScale),
            .init(activeAppearance: UITraitCollection.current.activeAppearance)
        ])
        let snapshot = MKMapSnapshotter(options: options)
        return try await withCheckedThrowingContinuation { continuation in
            snapshot.start(with: .global()) { snapshot, error in
                if let error = error { continuation.resume(with: .failure(error)) }
                continuation.resume(with: .success(snapshot!))
            }
        }
    }
}
