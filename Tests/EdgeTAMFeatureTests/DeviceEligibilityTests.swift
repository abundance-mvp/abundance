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

    @Test("iPhone 16 Pro variants are eligible")
    func iphone16ProEligible() {
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,1"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,2"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,3"))
        #expect(DeviceEligibility.isEligible(machine: "iPhone17,4"))
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

    #if targetEnvironment(simulator)
    @Test("Simulator is always eligible for testing")
    func simulatorEligible() {
        #expect(DeviceEligibility.isSweepModeAvailable)
    }
    #endif
}
