//
//  SpaceStationTrackerWidget.swift
//  SpaceStationTrackerWidget
//
//  Created by Joshua Homann on 10/9/22.
//

import WidgetKit
import SwiftUI
import Intents
import MapKit

struct Provider {
    @MainActor
    static func makeEntry(for location: TaggedSpaceStationLocation, with context: Context) async -> Entry {
        switch context.family {
        case .accessoryCircular, .accessoryCorner, .accessoryInline, .accessoryRectangular:
            return .text(location: location)
        case .systemExtraLarge, .systemLarge, .systemMedium, .systemSmall:
            let coordinate = location.coordinate
            guard let snap = try? await MKMapSnapshotter.makeSnapShot(
                coordinate: coordinate,
                span: .init(latitudeDelta: 20, longitudeDelta: 20),
                size: context.displaySize
            ) else {
                return .map(location: location, image: .init())
            }
            return .map(location: location, image: snap.image)
            
        @unknown default:
            return .text(location: location)
        }
    }
}

extension Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        .text(location: .sampleLocations[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task { @MainActor in
            let locations = (try? await SpaceStationLocationService().geoTaggedLocations()) ?? TaggedSpaceStationLocation.sampleLocations
            let entries = (try? await locations.parallelMap { location in
                await Self.makeEntry(for: location, with: context)
            }) ?? []
            completion(.init(entries: entries, policy: .atEnd))
        }
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task { @MainActor in
            let locations = (try? await SpaceStationLocationService().geoTaggedLocations()) ?? TaggedSpaceStationLocation.sampleLocations
            completion(await Self.makeEntry(for: locations[0], with: context))
        }
    }
}


enum Entry: TimelineEntry, Identifiable {
    case text(location: TaggedSpaceStationLocation), map(location: TaggedSpaceStationLocation, image: UIImage)
    var id: Int {
        switch self {
        case let .text(location), let .map(location, _): return location.id
        }
    }
    var date: Date {
        switch self {
        case let .text(location), let .map(location, _): return location.date
        }
    }
}

extension TaggedSpaceStationLocation: TimelineEntry, Identifiable {
    var date: Date {
        spaceStationLocation.date
    }
    var id: Int {
        spaceStationLocation.id
    }
}
struct SpaceStationTrackerWidgetEntryView : View {
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.locale) private var locale
    var entry: Provider.Entry
    @ViewBuilder
    var body: some View {
        switch entry {
        case let .text(location):
            if widgetFamily == .accessoryInline {
                Text("ISS over \(location.locationName)")
            } else {
                ZStack {
                    AccessoryWidgetBackground()
                    makeTextStackView(for: location)
                }
            }
        case let .map(location, image):
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: image).resizable()
                    .overlay(
                        Circle()
                            .foregroundColor(.red)
                            .shadow(color: .red, radius: 4)
                            .frame(width: 12, height: 12)

                    )
                makeTextStackView(for: location)
                    .padding()
                    .background(Material.regular)
                    .padding()
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    func makeTextStackView(for location: TaggedSpaceStationLocation) -> some View {
        let isMetric = locale.measurementSystem != .us
        let time = "\(location.date.formatted(.dateTime.hour()))"
        let name = location.locationName
        let altitude = location.altitudeKilometers.converted(to: isMetric ? .kilometers : .miles).formatted()
        let velocity = location.velocityKilometersPerHour.converted(to: isMetric ? .kilometersPerHour : .milesPerHour).formatted()
        ViewThatFits {
            VStack(alignment: .leading) {
                Text("Space station").font(.title3)
                Text(time)
                Text(name)
                Text(velocity)
                Text(altitude)
            }
            .font(.caption)
            VStack(alignment: .leading) {
                HStack {
                    Text(time)
                    Text(name)
                }
                HStack {
                    Text(velocity)
                    Text(altitude)
                }
            }
            .font(.caption)
            VStack(alignment: .center) {
                Text(time)
                Text(name)
            }
            .font(.caption)
        }
    }
}

@main
struct SpaceStationTrackerWidget: Widget {
    let kind: String = "SpaceStationTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SpaceStationTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Space Station Tracker")
        .supportedFamilies(
            [
                .systemSmall,
                .systemMedium,
                .systemLarge,
                .systemExtraLarge,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        )
        .description("Space Station Tracker")
    }
}

struct SpaceStationTrackerWidget_Previews: PreviewProvider {
    static let text = Entry.text(location:.sampleLocations[0])
    static let image = Entry.map(location:.sampleLocations[0], image: .init(named: "small")!)
    static var previews: some View {
        SpaceStationTrackerWidgetEntryView(entry: image)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
