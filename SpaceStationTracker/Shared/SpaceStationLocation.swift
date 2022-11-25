//
//  SpaceStationLocation.swift
//  SpaceStationTracker
//
//  Created by Joshua Homann on 10/9/22.
//

import Foundation
import MapKit

// https://wheretheiss.at/w/developer

struct SpaceStationLocation: Codable, Sendable {
    var name: String
    var id: Int
    var latitude, longitude: Double
    var altitude: Double
    var velocity: Double
    var visibility: String
    var footprint: Double
    var timestamp: Double
    var daynum, solarLat, solarLon: Double
    var units: Units

    enum Units: String, Codable {
        case miles, kilometers
    }

    enum CodingKeys: String, CodingKey {
        case name, id, latitude, longitude, altitude, velocity, visibility, footprint, timestamp, daynum
        case solarLat = "solar_lat"
        case solarLon = "solar_lon"
        case units
    }
}

extension SpaceStationLocation {
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
    var altitudeKilometers: Measurement<UnitLength> {
        .init(value: altitude, unit: .kilometers)
    }
    var velocityKilometersPerHour: Measurement<UnitSpeed> {
        .init(value: velocity, unit: .kilometersPerHour)
    }
    var date: Date {
        .init(timeIntervalSince1970: timestamp)
    }
}


@dynamicMemberLookup
struct TaggedSpaceStationLocation: Codable, Sendable {
    var spaceStationLocation: SpaceStationLocation
    var locationName: String
    subscript<Value>(dynamicMember keyPath: KeyPath<SpaceStationLocation, Value>) -> Value {
        spaceStationLocation[keyPath: keyPath]
    }
}

extension TaggedSpaceStationLocation {
    static var sampleLocations: [Self] {
        Self.sampleData.data(using: .utf8)
            .flatMap { try? JSONDecoder().decode([Self].self, from: $0) } ?? []
    }
    static private var sampleData: String {
    #"""
    [{"spaceStationLocation":{"id":25544,"footprint":4493.0805789282003,"velocity":27584.875592541001,"timestamp":1668268800,"longitude":24.344490114338001,"latitude":-6.2362424454339997,"units":"kilometers","solar_lat":-17.807500227533001,"visibility":"daylight","daynum":2459896.1666667,"solar_lon":296.04340016500998,"altitude":417.17841967651998,"name":"iss"},"locationName":"Kabinda"},{"spaceStationLocation":{"id":25544,"footprint":4566.3024570015004,"velocity":27540.206553472999,"timestamp":1668272400,"longitude":-134.12887751328,"latitude":-33.836945068147998,"units":"kilometers","solar_lat":-17.818692501445,"visibility":"daylight","daynum":2459896.2083333,"solar_lon":281.04475802847998,"altitude":431.65752047903999,"name":"iss"},"locationName":"South Pacific Ocean"},{"spaceStationLocation":{"id":25544,"footprint":4501.4321881734004,"velocity":27606.355332079002,"timestamp":1668276000,"longitude":100.9298967406,"latitude":51.166608295061998,"units":"kilometers","solar_lat":-17.829875837852999,"visibility":"eclipsed","daynum":2459896.25,"solar_lon":266.04612220562001,"altitude":418.81547013658002,"name":"iss"},"locationName":"Khövsgöl"},{"spaceStationLocation":{"id":25544,"footprint":4526.0880564335002,"velocity":27565.259419059999,"timestamp":1668279600,"longitude":-36.155413564207002,"latitude":-23.178242820346,"units":"kilometers","solar_lat":-17.841050228945999,"visibility":"daylight","daynum":2459896.2916667,"solar_lon":251.04749252854,"altitude":423.67004215854001,"name":"iss"},"locationName":"South Atlantic Ocean"},{"spaceStationLocation":{"id":25544,"footprint":4532.6543388697,"velocity":27557.163889721,"timestamp":1668283200,"longitude":163.05318147816001,"latitude":-17.945164441311,"units":"kilometers","solar_lat":-17.852215666932999,"visibility":"daylight","daynum":2459896.3333333,"solar_lon":236.04886882938001,"altitude":424.96835497298002,"name":"iss"},"locationName":"Coral Sea"},{"spaceStationLocation":{"id":25544,"footprint":4496.1474321389996,"velocity":27609.232492592,"timestamp":1668286800,"longitude":20.421427461057,"latitude":49.551499082348997,"units":"kilometers","solar_lat":-17.863372143633001,"visibility":"eclipsed","daynum":2459896.375,"solar_lon":221.05025144308999,"altitude":417.77914243536998,"name":"iss"},"locationName":"Czerniec 174"},{"spaceStationLocation":{"id":25544,"footprint":4564.2045140255996,"velocity":27545.373013531,"timestamp":1668290400,"longitude":-100.65675889550999,"latitude":-38.313934180048001,"units":"kilometers","solar_lat":-17.874519651256001,"visibility":"daylight","daynum":2459896.4166667,"solar_lon":206.05164020179001,"altitude":431.23868463104998,"name":"iss"},"locationName":"South Pacific Ocean"},{"spaceStationLocation":{"id":25544,"footprint":4505.4380819983999,"velocity":27574.450954847998,"timestamp":1668294000,"longitude":103.15129387803999,"latitude":-0.77062702905165004,"units":"kilometers","solar_lat":-17.885658182010001,"visibility":"daylight","daynum":2459896.4583333,"solar_lon":191.05303493755,"altitude":419.60200418096002,"name":"iss"},"locationName":"Sungai Kayu Aro"},{"spaceStationLocation":{"id":25544,"footprint":4484.5427369701001,"velocity":27609.905782639999,"timestamp":1668297600,"longitude":-52.823493990823003,"latitude":39.171456568714,"units":"kilometers","solar_lat":-17.896787727722,"visibility":"eclipsed","daynum":2459896.5,"solar_lon":176.05443261415999,"altitude":415.50868892683002,"name":"iss"},"locationName":"North Atlantic Ocean"},{"spaceStationLocation":{"id":25544,"footprint":4593.1521304913003,"velocity":27530.651311231999,"timestamp":1668301200,"longitude":-173.11862481072001,"latitude":-49.070078116443,"units":"kilometers","solar_lat":-17.907908280609998,"visibility":"daylight","daynum":2459896.5416667,"solar_lon":161.05583980597001,"altitude":437.03865919526999,"name":"iss"},"locationName":"South Pacific Ocean"}]

    """#
    }
}
