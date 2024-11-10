import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var sketches: [Sketch] = []
    private let session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            
            // Check cached context
            if let sketchData = session.receivedApplicationContext["sketches"] as? Data {
                do {
                    let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                    self.sketches = decodedSketches
                    print("Phone loaded \(decodedSketches.count) sketches from cached context")
                } catch {
                    print("Failed to decode cached sketches: \(error)")
                }
            }
            
            // Also request current sketches from Watch
            requestSketchesFromWatch()
        }
        print("WatchConnectivityManager initialized on Phone")
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
                        self.sketches = decodedSketches
                        print("Phone loaded \(decodedSketches.count) sketches from Watch")
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
                    self.sketches = decodedSketches
                    print("Phone received \(decodedSketches.count) sketches from context")
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
                    self.sketches = decodedSketches
                    print("Phone received \(decodedSketches.count) sketches")
                } catch {
                    print("Failed to decode sketches: \(error)")
                }
            }
        }
    }
} 