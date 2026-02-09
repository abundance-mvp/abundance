import Testing
@testable import EdgeTAMFeature

@Suite("Device Eligibility")
struct DeviceEligibilityTests {

    @Test("iPhone 15 Pro is eligible")
    func iphone15ProEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone16,1"))
    }

    @Test("iPhone 15 Pro Max is eligible")
    func iphone15ProMaxEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone16,2"))
    }

    @Test("iPhone 16 family is eligible")
    func iphone16FamilyEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,1"))  // iPhone 16
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,2"))  // iPhone 16 Plus
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,3"))  // iPhone 16 Pro
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,4"))  // iPhone 16 Pro Max
    }

    @Test("iPhone 16e is eligible (A18, 8GB)")
    func iphone16eEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,5"))
    }

    @Test("Future iPhone 18+ models are eligible")
    func futureModelsEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone18,1"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone19,3"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone20,1"))
    }

    @Test("iPhone 15 non-Pro is NOT eligible")
    func iphone15NotEligible() {
        #expect(!DeviceEligibility.isEligible(machine: "iPhone15,4"))
    }

    @Test("iPhone 14 Pro is NOT eligible (A16, not A17 Pro)")
    func iphone14ProNotEligible() {
        #expect(!DeviceEligibility.isEligible(machine: "iPhone15,2"))
    }

    @Test("iPhone SE is NOT eligible")
    func iphoneSENotEligible() {
        #expect(!DeviceEligibility.isEligible(machine: "iPhone14,6"))
    }

    @Test("Empty string is NOT eligible")
    func emptyStringNotEligible() {
        #expect(!DeviceEligibility.isEligible(machine: ""))
    }

    @Test("iPad is NOT eligible")
    func iPadNotEligible() {
        #expect(!DeviceEligibility.isEligible(machine: "iPad14,1"))
    }

    @Test("Models not available when .mlmodelc not bundled")
    func modelsNotAvailableWithoutBundle() {
        // Until real CoreML models are shipped, areModelsAvailable should be false
        #expect(!DeviceEligibility.areModelsAvailable)
    }

    #if targetEnvironment(simulator)
    @Test("Simulator hardware eligible but gated by model availability")
    func simulatorGatedByModels() {
        // Hardware check passes in simulator, but models aren't bundled yet
        #expect(!DeviceEligibility.isSweepModeAvailable)
    }
    #endif
}
