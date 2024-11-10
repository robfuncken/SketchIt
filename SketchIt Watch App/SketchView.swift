import SwiftUI
import WatchKit

struct SketchView: View {
    @Environment(\.dismiss) private var dismiss
    @State var sketch: Sketch
    @ObservedObject var sketchStore: SketchStore
    var isEditing: Bool = false
    @State private var currentLine: [CGPoint] = []
    @State private var lines: [[CGPoint]] = []
    @State private var isNamingSketch = false
    
    init(sketch: Sketch, sketchStore: SketchStore, isEditing: Bool = false) {
        _sketch = State(initialValue: sketch)
        self.sketchStore = sketchStore
        self.isEditing = isEditing
        
        // Convert the flat points array back into lines
        if !sketch.points.isEmpty {
            var reconstructedLines: [[CGPoint]] = []
            var currentLine: [CGPoint] = []
            
            for point in sketch.points {
                if point == CGPoint.zero {
                    // Zero point marks the end of a line
                    if !currentLine.isEmpty {
                        reconstructedLines.append(currentLine)
                        currentLine = []
                    }
                } else {
                    currentLine.append(point)
                }
            }
            
            // Add the last line if it exists
            if !currentLine.isEmpty {
                reconstructedLines.append(currentLine)
            }
            
            _lines = State(initialValue: reconstructedLines)
        } else {
            _lines = State(initialValue: [])
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
                    if isEditing {
                        // Direct save for editing existing sketches
                        saveAndDismiss()
                    } else {
                        // Show naming sheet only for new sketches
                        isNamingSketch = true
                    }
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
                        Button("Save") {
                            if sketch.name.isEmpty {
                                sketch.name = Date().formatted(date: .abbreviated, time: .shortened)
                            }
                            saveAndDismiss()
                        }
                        
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
        // Add a zero point between each line to mark line breaks
        var allPoints: [CGPoint] = []
        for line in lines {
            allPoints.append(contentsOf: line)
            allPoints.append(.zero)  // Add separator between lines
        }
        sketch.points = allPoints
        sketch.date = Date()
        
        if isEditing {
            sketchStore.updateSketch(sketch)
        } else {
            sketchStore.addSketch(sketch)
        }
    }
}

//#Preview {
//    SketchView()
//}
