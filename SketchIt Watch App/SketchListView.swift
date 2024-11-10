//
//  SketchListView.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//

import SwiftUI

struct SketchListView: View {
    @State private var sketches: [Sketch] = []
    @State private var showingNewSketch = false
    
    var body: some View {
        List {
            Button(action: {
                showingNewSketch = true
            }) {
                Label("New Sketch", systemImage: "plus.circle")
            }
            
            ForEach(sketches) { sketch in
                NavigationLink(destination: SketchView(sketch: sketch, sketches: $sketches)) {
                    VStack(alignment: .leading) {
                        Text(sketch.name)
                            .font(.headline)
                        Text(sketch.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onDelete(perform: deleteSketches)
        }
        .navigationTitle("Sketches")
        .sheet(isPresented: $showingNewSketch) {
            SketchView(sketch: Sketch(), sketches: $sketches)
        }
    }
    
    func deleteSketches(at offsets: IndexSet) {
        sketches.remove(atOffsets: offsets)
    }
}


#Preview {
    SketchListView()
}
