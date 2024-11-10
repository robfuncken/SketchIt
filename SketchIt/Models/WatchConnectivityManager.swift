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
            
            // get latest sketches if available
            if let context = session.receivedApplicationContext,
               let sketchData = context["sketches"] as? Data {
                do {
                    let decodedSketches = try JSONDecoder().decode([Sketch].self, from: sketchData)
                    self.sketches = decodedSketches
                    print("Phone loaded \(decodedSketches.count) cached sketches on launch")
                } catch {
                    print("Failed to decode cached sketches: \(error)")
                }
            }
        }
        print("WatchConnectivityManager initialized on Phone")
    }
    
    // MARK: - Required WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Phone session activation failed: \(error.localizedDescription)")
        } else {
            print("Phone session activated successfully")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Phone session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Phone session deactivated")
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
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