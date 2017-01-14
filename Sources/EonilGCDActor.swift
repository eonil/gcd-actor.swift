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

/// Mimics Go-lang's channel.
///
/// - Note:
///     `GCDChannel` object is supposed to have no buffered
///     value when it gets `deinit`ialized.
///     Make sure your program won't put any extra values
///     in channel.
///
///     - Ref 1: https://tour.golang.org/concurrency/2
///     - Ref 2: https://tour.golang.org/concurrency/3
///
///     `Closing channel` concept is not implemented.
///
public final class GCDChannel<T> {
    private let valueAvailabilitySemaphore = DispatchSemaphore(value: 0)
    private let capacityAvailabilitySemaphore: DispatchSemaphore
    private let lck = NSLock()
    /// Critical section. Always lock when you access this.
    private var buf = [T]()

    /// - Parameter capacity:
    ///     Set to 0 to make unbuffered channel which waits other side on both of
    ///     send and receive.
    ///     Set to non-zero value to make buffer channel which waits only if the
    ///     buffer is full.
    ///
    public init(capacity: Int = 0) {
        precondition(capacity >= 0, "Capacity must be >=0.")
        precondition(capacity <= 1024, "Capacity must be <=1024. This limit is set without a good reason. Remove this limit if you feed need for it.")
        // Pre-signal `capacityAvailabilitySemaphore`.
        capacityAvailabilitySemaphore = DispatchSemaphore(value: capacity)
    }
    //    public convenience init(_ initialValues: [T]) {
    //        self.init()
    //        buf = initialValues
    //    }
    deinit {
        debugUnmarkThread(of: self)
        assert(buf.isEmpty, "There's some remaining data in this channel. Your program is likely to have some bug.")
    }
    /// Gets availability of any signal.
    /// This also perform locking of internal memory.
    ///
    /// - Note:
    ///     I am not sure that this feature is really
    ///     required to be exposed or not.
    ///
    private var isAvailable: Bool {
        let returningValue: Bool
        lck.lock()
        returningValue = (buf.count > 0)
        lck.unlock()
        return returningValue
    }
    /// Blocks caller until a new value to be pushed if no value is now in channel.
    /// Beware deadlock.
    public func receive() -> T {
        debugAssertReceiving(of: self)
        // Pre-signal capacity availability.
        capacityAvailabilitySemaphore.signal()
        valueAvailabilitySemaphore.wait()
        let returningValue: T
        lck.lock()
        assert(buf.isEmpty == false)
        returningValue = buf.removeFirst()
        lck.unlock()
        return returningValue
    }
    public func send(_ newValue: T) {
        debugMarkThread(of: self)
        capacityAvailabilitySemaphore.wait()
        lck.lock()
        buf.append(newValue)
        lck.unlock()
        valueAvailabilitySemaphore.signal()
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











