import Foundation

/// Thermal monitoring and concurrency governor to protect battery life and prevent thermal throttling
/// during intensive on-device Apple Neural Engine (ANE) batch image classification.
public final class ThermalGovernor: @unchecked Sendable {
    
    public static let shared = ThermalGovernor()
    
    private let lock = NSLock()
    private var observers: [(ProcessInfo.ThermalState) -> Void] = []
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func thermalStateChanged() {
        let state = currentThermalState
        lock.lock()
        let callbacks = observers
        lock.unlock()
        
        for cb in callbacks {
            cb(state)
        }
    }
    
    public var currentThermalState: ProcessInfo.ThermalState {
        ProcessInfo.processInfo.thermalState
    }
    
    public var thermalStatusDescription: String {
        switch currentThermalState {
        case .nominal:  return "Nominal (Cool)"
        case .fair:     return "Fair (Warm)"
        case .serious:  return "Serious (Hot)"
        case .critical: return "Critical (Throttled)"
        @unknown default: return "Unknown"
        }
    }
    
    /// Returns the recommended maximum parallel batch size based on current thermal pressure.
    public var recommendedConcurrency: Int {
        switch currentThermalState {
        case .nominal:
            return 4
        case .fair:
            return 2
        case .serious:
            return 1
        case .critical:
            return 1
        @unknown default:
            return 2
        }
    }
    
    /// Returns the pacing sleep delay in nanoseconds to insert between batch classifications.
    public var pacingDelayNanoseconds: UInt64 {
        switch currentThermalState {
        case .nominal:
            return 0
        case .fair:
            return 10_000_000 // 10ms
        case .serious:
            return 50_000_000 // 50ms
        case .critical:
            return 150_000_000 // 150ms
        @unknown default:
            return 20_000_000
        }
    }
    
    public func addObserver(_ observer: @escaping (ProcessInfo.ThermalState) -> Void) {
        lock.lock()
        observers.append(observer)
        lock.unlock()
    }
}
