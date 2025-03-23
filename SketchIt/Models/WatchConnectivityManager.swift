import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var sketches: [Sketch] = []
    private let session: WCSession
    private let sketchesKey = "savedSketches"
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            loadSketches()
        }
        print("WatchConnectivityManager initialized on Phone")
    }
    
    private func loadSketches() {
        if let data = UserDefaults.standard.data(forKey: sketchesKey) {
            do {
                let decodedSketches = try JSONDecoder().decode([Sketch].self, from: data)
                self.sketches = decodedSketches
                print("Phone loaded \(decodedSketches.count) sketches from UserDefaults")
            } catch {
                print("Failed to load sketches from UserDefaults: \(error)")
            }
        }
        
        // After loading from local storage, sync with Watch
        requestSketchesFromWatch()
    }
    
    private func saveSketches() {
        do {
            let data = try JSONEncoder().encode(sketches)
            UserDefaults.standard.set(data, forKey: sketchesKey)
            print("Phone saved \(sketches.count) sketches to UserDefaults")
        } catch {
            print("Failed to save sketches to UserDefaults: \(error)")
        }
    }
    
    private func requestSketchesFromWatch() {
        guard session.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        try? session.sendMessage(["request": "getAllSketches"], replyHandler: { response in
            Task { @MainActor in
                if let sketchData = response["sketches"] as? Data {
                    do {
                        let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                        // Merge with existing sketches, keeping the most recent version
                        for watchSketch in decodedSketches {
                            if let index = self.sketches.firstIndex(where: { $0.id == watchSketch.id }) {
                                // Keep the most recently modified sketch
                                if watchSketch.lastModified > self.sketches[index].lastModified {
                                    self.sketches[index] = watchSketch
                                }
                            } else {
                                self.sketches.append(watchSketch)
                            }
                        }
                        self.saveSketches()
                        print("Phone merged \(decodedSketches.count) sketches from Watch")
                    } catch {
                        print("Failed to decode sketches from Watch: \(error)")
                    }
                }
            }
        }, errorHandler: { error in
            print("Failed to request sketches from Watch: \(error.localizedDescription)")
        })
    }
    
    func refreshSketches() {
        requestSketchesFromWatch()
    }
    
    func deleteSketch(_ sketch: Sketch) {
        sketches.removeAll { $0.id == sketch.id }
        saveSketches()
        
        // Send deletion to watch
        guard session.isReachable else {
            print("Watch is not reachable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(sketch.id)
            try session.sendMessage(["deleteSketch": data], replyHandler: { response in
                print("Watch acknowledged sketch deletion")
            }, errorHandler: { error in
                print("Failed to send sketch deletion to watch: \(error.localizedDescription)")
            })
            print("Sent sketch deletion to watch")
        } catch {
            print("Failed to encode sketch deletion: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate Methods
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Phone session activation failed: \(error.localizedDescription)")
            } else {
                print("Phone session activated successfully")
            }
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("Phone session became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            print("Phone session deactivated")
            session.activate()
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let sketchData = applicationContext["sketches"] as? Data {
                do {
                    let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                    // Merge with existing sketches, keeping the most recent version
                    for watchSketch in decodedSketches {
                        if let index = self.sketches.firstIndex(where: { $0.id == watchSketch.id }) {
                            // Keep the most recently modified sketch
                            if watchSketch.lastModified > self.sketches[index].lastModified {
                                self.sketches[index] = watchSketch
                            }
                        } else {
                            self.sketches.append(watchSketch)
                        }
                    }
                    self.saveSketches()
                    print("Phone merged \(decodedSketches.count) sketches from context")
                } catch {
                    print("Failed to decode sketches from context: \(error)")
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let sketchData = message["sketches"] as? Data {
                do {
                    let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                    // Merge with existing sketches, keeping the most recent version
                    for watchSketch in decodedSketches {
                        if let index = self.sketches.firstIndex(where: { $0.id == watchSketch.id }) {
                            // Keep the most recently modified sketch
                            if watchSketch.lastModified > self.sketches[index].lastModified {
                                self.sketches[index] = watchSketch
                            }
                        } else {
                            self.sketches.append(watchSketch)
                        }
                    }
                    self.saveSketches()
                    print("Phone merged \(decodedSketches.count) sketches from message")
                } catch {
                    print("Failed to decode sketches: \(error)")
                }
            } else if let deleteData = message["deleteSketch"] as? Data {
                do {
                    let sketchId = try JSONDecoder().decode(UUID.self, from: deleteData)
                    if self.sketches.contains(where: { $0.id == sketchId }) {
                        self.sketches.removeAll { $0.id == sketchId }
                        self.saveSketches()
                        print("Phone deleted sketch with ID: \(sketchId)")
                    }
                } catch {
                    print("Failed to decode sketch deletion: \(error)")
                }
            }
        }
    }
} 