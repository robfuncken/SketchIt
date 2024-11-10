//
//  WatchConnectivityManager.swift
//  SketchIt Watch App
//
//  Created by Rob Funcken on 10/11/2024.
//

import Foundation
import WatchConnectivity

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    private let session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
#if os(watchOS)
        print("WatchConnectivityManager initialized on Watch")
#else
        print("WatchConnectivityManager initialized on Phone")
#endif
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Session activation failed: \(error.localizedDescription)")
        } else {
            print("Session activated successfully")
        }
    }
    
#if os(watchOS)
    func sendSketchesToPhone(_ sketches: [Sketch]) {
        guard session.isReachable else {
            print("Phone is not reachable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(sketches)
            session.sendMessage(["sketches": data], replyHandler: nil) { error in
                print("Failed to send sketches: \(error.localizedDescription)")
            }
            print("Sent \(sketches.count) sketches to phone")
        } catch {
            print("Failed to encode sketches: \(error)")
        }
    }
#endif
    
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
        session.activate()
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
#endif
}
