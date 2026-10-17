import Foundation
import IOKit
import IOKit.ps

/// Reads the internal battery. Every source is public and unprivileged: IOKit's power sources for
/// what the system menu shows, and the AppleSmartBattery registry entry for the details.
public final class BatterySampler {
    private var service: io_service_t = 0

    public init() {}

    deinit { if service != 0 { IOObjectRelease(service) } }

    /// Nil on a Mac without a battery.
    public func sample() -> BatteryReading? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }
        let sources = list.compactMap {
            IOPSGetPowerSourceDescription(info, $0)?.takeUnretainedValue() as? [String: Any]
        }
        let adapter = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any]
        return Self.reading(
            sources: sources, registry: registry(), adapter: adapter,
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    /// The decision, apart from the system calls, so tests can feed it recorded dictionaries.
    static func reading(
        sources: [[String: Any]], registry: [String: Any], adapter: [String: Any]?, lowPowerMode: Bool
    ) -> BatteryReading? {
        guard
            let d = sources.first(where: {
                $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType && $0[kIOPSIsPresentKey] as? Bool ?? true
            }),
            let current = d[kIOPSCurrentCapacityKey] as? Int,
            let max = d[kIOPSMaxCapacityKey] as? Int, max > 0
        else { return nil }

        let level = min(Double(current) / Double(max), 1)
        let onPower = d[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
        let charging = d[kIOPSIsChargingKey] as? Bool ?? false
        // Not every Mac publishes Is Charged, so a full battery on power counts as charged too.
        let charged = d[kIOPSIsChargedKey] as? Bool ?? (onPower && !charging && current >= max)
        let state: BatteryReading.State =
            charging ? .charging : charged && onPower ? .charged : onPower ? .notCharging : .discharging

        // Negative means macOS is still estimating. A battery that isn't moving has no time to show.
        let minutes = (charging ? d[kIOPSTimeToFullChargeKey] : d[kIOPSTimeToEmptyKey]) as? Int
        let remaining = minutes.flatMap { $0 >= 0 && (state == .charging || state == .discharging) ? $0 : nil }

        func int(_ key: String) -> Int? { (registry[key] as? NSNumber)?.intValue }
        // IOKit stores a negative current as its 64-bit two's complement; Int64 reads it back as signed.
        let amperage = (registry["Amperage"] as? NSNumber)?.int64Value
        let voltage = (registry["Voltage"] as? NSNumber)?.int64Value
        let watts = amperage.flatMap { a in voltage.map { v in Double(a) * Double(v) / 1_000_000 } }
        // Apple silicon reports MaxCapacity as a percentage and the mAh figure as AppleRawMaxCapacity.
        let fullCharge = int("AppleRawMaxCapacity") ?? int("MaxCapacity").flatMap { $0 > 100 ? $0 : nil }
        let remainingCharge = int("AppleRawCurrentCapacity") ?? int("CurrentCapacity").flatMap { $0 > 100 ? $0 : nil }

        return BatteryReading(
            level: level, state: state, minutesRemaining: remaining, isLowPowerMode: lowPowerMode,
            adapterWatts: onPower ? adapter?[kIOPSPowerAdapterWattsKey] as? Int : nil,
            cycleCount: int("CycleCount"), designCycleCount: d["DesignCycleCount"] as? Int,
            fullChargeCapacity: fullCharge, designCapacity: int("DesignCapacity"),
            temperature: int("Temperature").map { Double($0) / 100 }, watts: watts,
            current: amperage.map { Int($0) }, remainingCapacity: remainingCharge)
    }

    /// Only the keys used, read one at a time: the whole entry carries kilobytes of gauge data.
    private func registry() -> [String: Any] {
        if service == 0 {
            service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        }
        guard service != 0 else { return [:] }
        var values: [String: Any] = [:]
        for key in Self.registryKeys {
            values[key] = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue()
        }
        return values
    }

    static let registryKeys = [
        "Amperage", "Voltage", "CycleCount", "AppleRawMaxCapacity", "MaxCapacity", "AppleRawCurrentCapacity",
        "CurrentCapacity", "DesignCapacity", "Temperature",
    ]
}
