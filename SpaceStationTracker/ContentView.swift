//
//  ContentView.swift
//  SpaceStationTracker
//
//  Created by Joshua Homann on 10/9/22.
//

import SwiftUI
import MapKit

struct SpaceStationLocationServiceEnvironmentKey: EnvironmentKey {
    static var defaultValue: SpaceStationLocationService = .init()
}

extension EnvironmentValues {
    var spaceStationLocationService: SpaceStationLocationService {
        get { self[SpaceStationLocationServiceEnvironmentKey.self] }
    }
}

@MainActor
final class StationMapViewModel: ObservableObject {
    @Published private(set) var annotations: [Annotation] = []
    @Published var region = MKCoordinateRegion(.world)
    @Published var showList = false
    @Published var selectedAnnotation: Annotation?
    func callAsFunction(locale: Locale, spaceStationLocationService: SpaceStationLocationService) async {
        let locations = (try? await spaceStationLocationService.geoTaggedLocations()) ?? []
        let isMetric = locale.measurementSystem != .us
        annotations = locations.map { tagged in
            .init(
                id: UUID().uuidString,
                coordinate: tagged.coordinate,
                name: tagged.locationName,
                time: tagged.date.formatted(.dateTime.hour()),
                altitude: tagged.altitudeKilometers.converted(to: isMetric ? .kilometers : .miles).formatted(),
                velocity: tagged.velocityKilometersPerHour.converted(to: isMetric ? .kilometersPerHour : .milesPerHour).formatted()
            )
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = StationMapViewModel()
    @Environment(\.locale) private var locale
    @Environment(\.spaceStationLocationService) private var spaceStationLocationService
    var body: some View {
        NavigationStack {
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.annotations) { annotation in
                MapAnnotation(coordinate: annotation.coordinate, anchorPoint: .init(x: 0.5, y: 0.5)) {
                    AnnotationView(selectedAnnotation: $viewModel.selectedAnnotation, annotation: annotation)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("ISS Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showList.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
            }
        }
        .task {
            await viewModel.callAsFunction(locale: locale, spaceStationLocationService: spaceStationLocationService)
        }
        .sheet(isPresented: $viewModel.showList) {
            List(viewModel.annotations) { annotation in
                VStack(alignment: .leading) {
                    HStack {
                        Text(annotation.time).font(.title3).bold()
                        Text(annotation.name).font(.body)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(annotation.altitude)
                        Text(annotation.velocity)
                    }
                    .font(.caption)
                }
                .onTapGesture {
                    viewModel.selectedAnnotation = annotation
                    viewModel.showList = false
                    viewModel.region = .init(center: annotation.coordinate, span: .init(latitudeDelta: 60, longitudeDelta: 60))
                }
            }
            .presentationDetents([.large, .medium, .fraction(0.2)])
        }
    }
}

struct Annotation: Identifiable {
    var id: String
    var coordinate: CLLocationCoordinate2D
    var name: String
    var time: String
    var altitude: String
    var velocity: String
}

struct AnnotationView: View {
    @Binding var selectedAnnotation: Annotation?
    var annotation: Annotation
    var body: some View {
        Button {
            selectedAnnotation = selectedAnnotation?.id == annotation.id ? nil : annotation
        } label: {
            GroupBox(annotation.time) {
                if selectedAnnotation?.id == annotation.id {
                    VStack(alignment: .leading) {
                        Text(annotation.name).font(.title3)
                        Text(annotation.velocity)
                        Text(annotation.altitude)
                    }
                    .font(.caption)
                } else {
                    EmptyView()
                }
            }
            .backgroundStyle(Color.white)
            .accentColor(.primary)
            .fixedSize()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
