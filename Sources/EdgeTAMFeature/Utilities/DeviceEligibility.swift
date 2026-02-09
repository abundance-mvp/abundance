import Foundation

/// Checks if the current device supports EdgeTAM sweep mode.
///
/// Requires A17 Pro / A18 Neural Engine (35 TOPS, 8GB RAM) or later:
/// - iPhone 15 Pro (iPhone16,1)
/// - iPhone 15 Pro Max (iPhone16,2)
/// - iPhone 16 Pro family (iPhone17,1–4)
/// - iPhone 16e (iPhone17,5) — A18, 8GB RAM, same Neural Engine throughput
/// - Future models (iPhone18+)
public enum DeviceEligibility: Sendable {

    /// Check if sweep mode is available on the current device.
    /// Requires both eligible hardware AND bundled CoreML models.
    /// Always returns true for hardware in Simulator; model check still applies.
    public static var isSweepModeAvailable: Bool {
        let hardwareOK: Bool
        #if targetEnvironment(simulator)
        hardwareOK = true
        #else
        hardwareOK = isEligible(machine: currentMachine())
        #endif
        return hardwareOK && areModelsAvailable
    }

    /// Check if the device hardware supports sweep mode (ignores model availability).
    /// Use this to show/hide sweep UI even before models are bundled.
    public static var isHardwareEligible: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return isEligible(machine: currentMachine())
        #endif
    }

    /// Returns true only when all three EdgeTAM CoreML model bundles are present.
    /// This gates the UI until models are actually shipped.
    public static var areModelsAvailable: Bool {
        let config = EdgeTAMConfiguration.default
        let names = [config.imageEncoderName, config.promptEncoderName, config.maskDecoderName]
        return names.allSatisfy { name in
            Bundle.module.url(forResource: name, withExtension: "mlmodelc") != nil
        }
    }

    /// Testable eligibility check (takes machine string as parameter)
    public static func isEligible(machine: String) -> Bool {
        let eligibleModels: Set<String> = [
            "iPhone16,1",  // iPhone 15 Pro
            "iPhone16,2",  // iPhone 15 Pro Max
            "iPhone17,1",  // iPhone 16 Pro
            "iPhone17,2",  // iPhone 16 Pro Max
            "iPhone17,3",  // iPhone 16 Pro (variant)
            "iPhone17,4",  // iPhone 16 Pro Max (variant)
            "iPhone17,5",  // iPhone 16e (A18, 8GB)
        ]

        if eligibleModels.contains(machine) {
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
