import Foundation

/// Checks if the current device supports EdgeTAM sweep mode.
///
/// Requires A17 Pro Neural Engine (35 TOPS) or later:
/// - iPhone 15 Pro (iPhone16,1)
/// - iPhone 15 Pro Max (iPhone16,2)
/// - iPhone 16 Pro family (iPhone17,x)
/// - Future Pro models (iPhone18+)
///
/// Note: A18 chip in standard iPhone 16 (iPhone17,5+) is excluded intentionally.
/// While it has 16 Neural Engine cores, EdgeTAM requires the A17 Pro's higher
/// memory bandwidth and throughput for real-time inference at acceptable FPS.
public enum DeviceEligibility: Sendable {

    /// Check if sweep mode is available on the current device.
    /// Always returns true in Simulator for testing.
    public static var isSweepModeAvailable: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        let machine = currentMachine()
        return isEligible(machine: machine)
        #endif
    }

    /// Testable eligibility check (takes machine string as parameter)
    public static func isEligible(machine: String) -> Bool {
        let proModels: Set<String> = [
            "iPhone16,1",  // iPhone 15 Pro
            "iPhone16,2",  // iPhone 15 Pro Max
            "iPhone17,1",  // iPhone 16 Pro
            "iPhone17,2",  // iPhone 16 Pro Max
            "iPhone17,3",  // iPhone 16 Pro (variant)
            "iPhone17,4",  // iPhone 16 Pro Max (variant)
        ]

        if proModels.contains(machine) {
            return true
        }

        // Future-proof: Any iPhone18+ is assumed to be capable
        if let range = machine.range(of: #"iPhone(\d+),"#, options: .regularExpression) {
            let numberStr = String(machine[range])
                .replacingOccurrences(of: "iPhone", with: "")
                .replacingOccurrences(of: ",", with: "")
            if let number = Int(numberStr), number >= 18 {
                return true
            }
        }

        return false
    }

    private static func currentMachine() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(
            bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)),
            encoding: .ascii
        )?.trimmingCharacters(in: .controlCharacters) ?? ""
    }
}
