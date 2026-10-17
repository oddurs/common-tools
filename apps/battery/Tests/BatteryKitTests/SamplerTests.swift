import Foundation
import IOKit.ps
import Testing

@testable import BatteryKit

/// The decoding of recorded power-source and registry dictionaries, shaped like a MacBook Pro's.
struct SamplerTests {
    func source(
        current: Int = 21, max: Int = 100, onPower: Bool = false, charging: Bool = false, charged: Bool? = nil,
        toEmpty: Int = 47, toFull: Int = 0
    ) -> [String: Any] {
        var d: [String: Any] = [
            kIOPSTypeKey: kIOPSInternalBatteryType, kIOPSIsPresentKey: true, kIOPSCurrentCapacityKey: current,
            kIOPSMaxCapacityKey: max, kIOPSPowerSourceStateKey: onPower ? kIOPSACPowerValue : kIOPSBatteryPowerValue,
            kIOPSIsChargingKey: charging, kIOPSTimeToEmptyKey: toEmpty, kIOPSTimeToFullChargeKey: toFull,
            "DesignCycleCount": 1000,
        ]
        if let charged { d[kIOPSIsChargedKey] = charged }
        return d
    }

    func read(_ source: [String: Any], registry: [String: Any] = [:], adapter: [String: Any]? = nil)
        -> BatteryReading?
    {
        BatterySampler.reading(sources: [source], registry: registry, adapter: adapter, lowPowerMode: false)
    }

    @Test func discharging() throws {
        let r = try #require(read(source()))
        #expect(r.state == .discharging)
        #expect(r.percent == 21)
        #expect(r.minutesRemaining == 47)
        #expect(r.designCycleCount == 1000)
    }

    @Test func estimatingHasNoTime() throws {
        let r = try #require(read(source(toEmpty: -1)))
        #expect(r.minutesRemaining == nil)
    }

    @Test func chargingCountsTimeToFull() throws {
        let r = try #require(read(source(current: 45, onPower: true, charging: true, toEmpty: 0, toFull: 52)))
        #expect(r.state == .charging)
        #expect(r.minutesRemaining == 52)
    }

    @Test func chargedHasNoTime() throws {
        let r = try #require(read(source(current: 100, onPower: true, charged: true, toEmpty: 0)))
        #expect(r.state == .charged)
        #expect(r.minutesRemaining == nil)
    }

    @Test func fullOnPowerWithoutIsChargedCountsAsCharged() throws {
        #expect(read(source(current: 100, onPower: true))?.state == .charged)
    }

    @Test func holdingBelowFullIsNotCharging() throws {
        // Optimized Charging or a charge limit parks the battery at 80% on power.
        let r = try #require(read(source(current: 80, onPower: true, charged: false, toEmpty: 0)))
        #expect(r.state == .notCharging)
        #expect(r.minutesRemaining == nil)
    }

    @Test func intelReportsMilliampHours() throws {
        let r = try #require(read(source(current: 3000, max: 6000)))
        #expect(r.percent == 50)
    }

    @Test func onlyTheInternalBatteryCounts() {
        var ups = source()
        ups[kIOPSTypeKey] = kIOPSUPSType
        #expect(read(ups) == nil)
        var absent = source()
        absent[kIOPSIsPresentKey] = false
        #expect(read(absent) == nil)
    }

    @Test func negativeCurrentReadsAsDischargeWatts() throws {
        // IOKit hands a negative current back as its 64-bit two's complement.
        let registry: [String: Any] = [
            "Amperage": NSNumber(value: UInt64(18_446_744_073_709_549_718)), "Voltage": NSNumber(value: 11112),
            "Temperature": NSNumber(value: 2971), "CycleCount": NSNumber(value: 156),
            "AppleRawMaxCapacity": NSNumber(value: 7872), "MaxCapacity": NSNumber(value: 100),
            "DesignCapacity": NSNumber(value: 8579), "AppleRawCurrentCapacity": NSNumber(value: 1648),
            "CurrentCapacity": NSNumber(value: 21),
        ]
        let r = try #require(read(source(), registry: registry))
        let watts = try #require(r.watts)
        #expect(abs(watts - -21.09) < 0.01)
        #expect(r.temperature == 29.71)
        #expect(r.cycleCount == 156)
        #expect(r.fullChargeCapacity == 7872)
        #expect(r.designCapacity == 8579)
        #expect(r.current == -1898)
        #expect(r.remainingCapacity == 1648)
    }

    @Test func maxCapacityIsMilliampHoursOnlyWhenItIsntAPercentage() throws {
        let intel = try #require(
            read(source(), registry: ["MaxCapacity": NSNumber(value: 5103), "CurrentCapacity": NSNumber(value: 1071)]))
        #expect(intel.fullChargeCapacity == 5103)
        #expect(intel.remainingCapacity == 1071)
        let silicon = try #require(
            read(source(), registry: ["MaxCapacity": NSNumber(value: 100), "CurrentCapacity": NSNumber(value: 21)]))
        #expect(silicon.fullChargeCapacity == nil)
        #expect(silicon.remainingCapacity == nil)
    }

    @Test func adapterOnlyWhileOnPower() throws {
        let adapter: [String: Any] = [kIOPSPowerAdapterWattsKey: 96]
        #expect(read(source(current: 80, onPower: true, charging: true), adapter: adapter)?.adapterWatts == 96)
        #expect(read(source(), adapter: adapter)?.adapterWatts == nil)
    }
}
