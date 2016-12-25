import Foundation
import Dispatch

public enum GCDActor {
    @discardableResult
    public static func spawn(_ f: @escaping (_ self: GCDActorSelf) -> ()) -> GCDActorRef {
        debugAssertCurrentThreadCountIsUnderPerProcessThreadCountLimit()
        return GCDActorImpl(f)
    }
}
public protocol GCDActorSelf: class {
    func pause()
    func sleep(for duration: DispatchTimeInterval)
    func sleep(for duration: TimeInterval)
}
public protocol GCDActorRef: class {
    func resume()
}
fileprivate final class GCDActorImpl: GCDActorSelf, GCDActorRef {
    private let gcdq = DispatchQueue(label: "GCDActor/GCDQ")
    private let sema = DispatchSemaphore(value: 0)
    fileprivate init(_ f: @escaping (_ self: GCDActorSelf) -> ()) {
        gcdq.async {
            // Lifetime of `self` is defined by execution of the function `f`.
            // So it will be extended until the function finishes.
            f(self)
        }
    }
    func pause() {
        debugLog("pause start")
        sema.wait()
        debugLog("pause finish")
    }
    func resume() {
        debugLog("resume start")
        sema.signal()
        debugLog("resume finish")
    }
    func sleep(for duration: DispatchTimeInterval) {
        debugLog(duration)
        DispatchQueue.global().asyncAfter(deadline: .now() + duration) {
            self.resume()
        }
        pause()
    }
    func sleep(for duration: TimeInterval) {
        // FIXME: Can crash. Define and limit valid range.
        let b = Int(duration * TimeInterval(kSecondScale))
        let a = DispatchTimeInterval.nanoseconds(b)
        sleep(for: a)
    }
}

public final class GCDChannel<T> {
    /// Critical section. Always lock when you access this.
    private var buf = [T]()
    private let smp = DispatchSemaphore(value: 0)
    private let lck = NSLock()
    public init() {
    }
    public convenience init(_ initialValues: [T]) {
        self.init()
        buf = initialValues
    }
    deinit {
        debugUnmarkThread(of: self)
    }
    /// Blocks caller until a new value to be pushed if no value is now in channel.
    /// Beware deadlock.
    public func receive() -> T {
        debugAssertReceiving(of: self)
        smp.wait()
        let tmp1: T
        lck.lock()
        assert(buf.isEmpty == false)
        tmp1 = buf.removeFirst()
        lck.unlock()
        return tmp1
    }
    public func send(_ newValue: T) {
        debugMarkThread(of: self)
        lck.lock()
        buf.append(newValue)
        lck.unlock()
        smp.signal()
    }
}

#if EonilGCDActorDebug
    private let debugLock = NSLock()
    private var debugChannelThreadMapping = [ObjectIdentifier: Thread]()
    private func debugAssertCurrentThreadCountIsUnderPerProcessThreadCountLimit() {

    }
    private func debugAssertReceiving<T>(of channel: GCDChannel<T>) {
        assert(debugChannelThreadMapping[ObjectIdentifier(channel)] != Thread.current, "In theory, it's fine to push/pop in same thread, but it is not likely to happen, and more likely to be a programmer error to make deadlock. So assert for it.")
    }
    private func debugMarkThread<T>(of channel: GCDChannel<T>) {
        debugLock.lock()
        debugChannelThreadMapping[ObjectIdentifier(channel)] = Thread.current
        debugLock.unlock()
    }
    private func debugUnmarkThread<T>(of channel: GCDChannel<T>) {
        debugLock.lock()
        debugChannelThreadMapping[ObjectIdentifier(channel)] = nil
        debugLock.unlock()
    }
    private func debugLog<T>(_ v: @autoclosure () -> T) {
        print("\(Date()): \(v())")
    }
#else
    private func debugAssertCurrentThreadCountIsUnderPerProcessThreadCountLimit() {
    }
    private func debugAssertReceiving<T>(of channel: @autoclosure () -> GCDChannel<T>) {
    }
    private func debugMarkThread<T>(of channel: @autoclosure () -> GCDChannel<T>) {
    }
    private func debugUnmarkThread<T>(of channel: @autoclosure () -> GCDChannel<T>) {
    }
    private func debugLog<T>(_ v: @autoclosure () -> T) {
    }
#endif

final class Watch {
    func incrementActorCount() {

    }
    func decrementActorCount() {

    }
}

private let watchQueue = DispatchQueue(label: "Watch", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
private var isWatching = false
private func watch() {
    watchQueue.async {
        guard isWatching == false else { return }

    }
}











