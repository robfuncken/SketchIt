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
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        print("WatchSketchStore initialized on Watch")
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
        sendSketchesToPhone()
    }
    
    func updateSketch(_ sketch: Sketch) {
        if let index = sketches.firstIndex(where: { $0.id == sketch.id }) {
            sketches[index] = sketch
            sendSketchesToPhone()
        }
    }
    
    func deleteSketch(_ sketch: Sketch) {
        sketches.removeAll { $0.id == sketch.id }
        sendSketchesToPhone()
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
}
