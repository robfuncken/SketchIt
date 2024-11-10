//
//  SketchStore.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//

import SwiftUI

@MainActor
class SketchStore: ObservableObject {
    @Published var sketches: [Sketch] = []
    private let saveKey = "SavedSketches"
    
    init() {
        loadSketches()
    }
    
    func addSketch(_ sketch: Sketch) {
        sketches.append(sketch)
        saveSketches()
    }
    
    func updateSketch(_ sketch: Sketch) {
        if let index = sketches.firstIndex(where: { $0.id == sketch.id }) {
            sketches[index] = sketch
            saveSketches()
        }
    }
    
    func deleteSketch(_ sketch: Sketch) {
        sketches.removeAll { $0.id == sketch.id }
        saveSketches()
    }
    
    private func saveSketches() {
        do {
            let data = try JSONEncoder().encode(sketches)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save sketches: \(error.localizedDescription)")
        }
    }
    
    private func loadSketches() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            sketches = try JSONDecoder().decode([Sketch].self, from: data)
        } catch {
            print("Failed to load sketches: \(error.localizedDescription)")
        }
    }
}
