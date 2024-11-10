//
//  Sketch.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//
import SwiftUI

struct Sketch: Identifiable, Codable {
    let id: UUID
    var name: String
    var points: [CGPoint]
    var date: Date
    
    init(id: UUID = UUID(), name: String = "New Sketch", points: [CGPoint] = [], date: Date = Date()) {
        self.id = id
        self.name = name
        self.points = points
        self.date = date
    }
}

// Make CGPoint codable for storage
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x
        case y
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
}
