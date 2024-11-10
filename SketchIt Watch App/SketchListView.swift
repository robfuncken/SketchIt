//
//  SketchListView.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//

import SwiftUI

struct SketchListView: View {
    @StateObject private var sketchStore = SketchStore()
    @State private var showingNewSketch = false
    @State private var selectedSketch: Sketch?
    
    var body: some View {
        List {
            Button(action: {
                showingNewSketch = true
            }) {
                Label("New Sketch", systemImage: "plus.circle")
            }
            
            ForEach(sketchStore.sketches) { sketch in
                Button(action: {
                    selectedSketch = sketch
                }) {
                    VStack(alignment: .leading) {
                        Text(sketch.name)
                            .font(.headline)
                        Text(sketch.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onDelete(perform: deleteSketch)
        }
        .navigationTitle("Sketches")
        .sheet(isPresented: $showingNewSketch) {
            SketchView(sketch: Sketch(), sketchStore: sketchStore)
        }
        .sheet(item: $selectedSketch) { sketch in
            SketchView(sketch: sketch, sketchStore: sketchStore, isEditing: true)
        }
    }
    
    private func deleteSketch(at offsets: IndexSet) {
        for index in offsets {
            let sketch = sketchStore.sketches[index]
            sketchStore.deleteSketch(sketch)
        }
    }
}

#Preview {
    SketchListView()
}
