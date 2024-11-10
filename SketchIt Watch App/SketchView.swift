import SwiftUI

struct SketchView: View {
    @Environment(\.dismiss) private var dismiss
    @State var sketch: Sketch
    @Binding var sketches: [Sketch]
    @State private var currentLine: [CGPoint] = []
    @State private var lines: [[CGPoint]] = []
    @State private var isNamingSketch = false
    
    init(sketch: Sketch, sketches: Binding<[Sketch]>) {
        _sketch = State(initialValue: sketch)
        _sketches = sketches
        // Convert the flat points array back into lines
        if !sketch.points.isEmpty {
            // Assuming each line has at least 2 points
            var currentPoints: [CGPoint] = []
            for point in sketch.points {
                currentPoints.append(point)
                if currentPoints.count >= 2 {
                    _lines = State(initialValue: [currentPoints])
                    currentPoints = []
                }
            }
            if !currentPoints.isEmpty {
                _lines = State(initialValue: [currentPoints])
            }
        }
    }
    
    var body: some View {
        Canvas { context, size in
            for line in lines {
                var path = Path()
                if let firstPoint = line.first {
                    path.move(to: firstPoint)
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                context.stroke(path, with: .color(.white), lineWidth: 2)
            }
            
            if !currentLine.isEmpty {
                var path = Path()
                path.move(to: currentLine[0])
                for point in currentLine.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(path, with: .color(.white), lineWidth: 2)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = value.location
                    if currentLine.isEmpty {
                        currentLine = [point]
                    } else {
                        currentLine.append(point)
                    }
                }
                .onEnded { _ in
                    if !currentLine.isEmpty {
                        lines.append(currentLine)
                        currentLine = []
                    }
                }
        )
        .navigationTitle(sketch.name)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    isNamingSketch = true
                }
            }
        }
        .sheet(isPresented: $isNamingSketch) {
            NavigationStack {
                List {
                    Section {
                        TextField("Sketch name", text: $sketch.name)
                    }
                    
                    Section {
                        Button("Quick Save") {
                            sketch.name = "Sketch \(Date().formatted(date: .abbreviated, time: .shortened))"
                            saveAndDismiss()
                        }
                        
                        Button("Save") {
                            saveAndDismiss()
                        }
                        .disabled(sketch.name.isEmpty)
                        
                        Button("Cancel", role: .cancel) {
                            isNamingSketch = false
                        }
                    }
                }
            }
        }
        .background(Color.black)
    }
    
    private func saveAndDismiss() {
        saveSketch()
        isNamingSketch = false
        dismiss()
    }
    
    private func saveSketch() {
        sketch.points = lines.flatMap { $0 }
        sketch.date = Date()
        
        if let index = sketches.firstIndex(where: { $0.id == sketch.id }) {
            sketches[index] = sketch
        } else {
            sketches.append(sketch)
        }
    }
}
