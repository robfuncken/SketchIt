//
//  ContentView.swift
//  SketchIt
//
//  Created by Rob Funcken on 10/11/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(connectivityManager.sketches) { sketch in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(sketch.name)
                            .font(.headline)
                        Text(sketch.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        SketchPreviewView(sketch: sketch)
                            .frame(height: 200)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: deleteSketches)
            }
            .navigationTitle("Sketches")
            .refreshable {
                connectivityManager.refreshSketches()
            }
            .onAppear {
                print("ContentView appeared")
                print("Number of sketches: \(connectivityManager.sketches.count)")
                connectivityManager.refreshSketches()
            }
        }
    }
    
    private func deleteSketches(at offsets: IndexSet) {
        for index in offsets {
            let sketch = connectivityManager.sketches[index]
            connectivityManager.deleteSketch(sketch)
        }
    }
}

struct SketchPreviewView: View {
    let sketch: Sketch
    
    var body: some View {
        Canvas { context, size in
            var currentLine: [CGPoint] = []
            for point in sketch.points {
                if point == .zero {
                    // Draw the current line
                    if currentLine.count > 1 {
                        var path = Path()
                        path.move(to: currentLine[0])
                        for point in currentLine.dropFirst() {
                            path.addLine(to: point)
                        }
                        context.stroke(path, with: .color(.black), lineWidth: 2)
                    }
                    currentLine = []
                } else {
                    currentLine.append(point)
                }
            }
            // Draw any remaining points
            if currentLine.count > 1 {
                var path = Path()
                path.move(to: currentLine[0])
                for point in currentLine.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(path, with: .color(.black), lineWidth: 2)
            }
        }
    }
}

#Preview {
    ContentView()
}

