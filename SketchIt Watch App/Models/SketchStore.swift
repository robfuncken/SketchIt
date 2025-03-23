//
//  SketchStore.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//

import Foundation
import WatchConnectivity

@MainActor
class WatchSketchStore: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSketchStore()
    @Published var sketches: [Sketch] = []
    private let session: WCSession
    private let sketchesKey = "savedSketches"
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        loadSketches()
        print("WatchSketchStore initialized on Watch")
    }
    
    private func loadSketches() {
        if let data = UserDefaults.standard.data(forKey: sketchesKey) {
            do {
                sketches = try JSONDecoder().decode([Sketch].self, from: data)
                print("Loaded \(sketches.count) sketches from UserDefaults")
            } catch {
                print("Failed to load sketches from UserDefaults: \(error)")
            }
        }
    }
    
    private func saveSketches() {
        do {
            let data = try JSONEncoder().encode(sketches)
            UserDefaults.standard.set(data, forKey: sketchesKey)
            print("Saved \(sketches.count) sketches to UserDefaults")
        } catch {
            print("Failed to save sketches to UserDefaults: \(error)")
        }
    }
    
    // MARK: - Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed: \(error.localizedDescription)")
        } else {
            print("Session activated successfully")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch session reachability changed: \(session.isReachable)")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let sketchData = applicationContext["sketches"] as? Data {
                do {
                    let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                    self.sketches = decodedSketches
                    print("Watch received \(decodedSketches.count) sketches from context")
                } catch {
                    print("Failed to decode sketches from context: \(error)")
                }
            }
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
    
    func addSketch(_ sketch: Sketch) {
        sketches.append(sketch)
        saveSketches()
        sendSketchesToPhone()
    }
    
    func updateSketch(_ sketch: Sketch) {
        if let index = sketches.firstIndex(where: { $0.id == sketch.id }) {
            sketches[index] = sketch
            saveSketches()
            sendSketchesToPhone()
        }
    }
    
    func deleteSketch(_ sketch: Sketch) {
        sketches.removeAll { $0.id == sketch.id }
        saveSketches()
        
        // Send deletion to phone
        guard session.isReachable else {
            print("Phone is not reachable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(sketch.id)
            try session.sendMessage(["deleteSketch": data], replyHandler: nil) { error in
                print("Failed to send sketch deletion: \(error.localizedDescription)")
            }
            print("Sent sketch deletion to phone")
        } catch {
            print("Failed to encode sketch deletion: \(error)")
        }
    }
    
    private func sendSketchesToPhone() {
        guard session.isReachable else {
            print("Phone is not reachable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(sketches)
            try session.updateApplicationContext(["sketches": data])
            print("Sent \(sketches.count) sketches to phone")
        } catch {
            print("Failed to send sketches to phone: \(error)")
        }
    }
    
    // Add this new method
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            if message["request"] as? String == "getAllSketches" {
                do {
                    let data = try JSONEncoder().encode(sketches)
                    print("Watch sending \(sketches.count) sketches in response to request")
                    replyHandler(["sketches": data])
                } catch {
                    print("Watch failed to encode sketches: \(error)")
                    replyHandler([:])
                }
            } else if let deleteData = message["deleteSketch"] as? Data {
                do {
                    let sketchId = try JSONDecoder().decode(UUID.self, from: deleteData)
                    if sketches.contains(where: { $0.id == sketchId }) {
                        sketches.removeAll { $0.id == sketchId }
                        saveSketches()
                        print("Watch deleted sketch with ID: \(sketchId)")
                    }
                    replyHandler([:])
                } catch {
                    print("Watch failed to decode sketch deletion: \(error)")
                    replyHandler([:])
                }
            }
        }
    }
}
