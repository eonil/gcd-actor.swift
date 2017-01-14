import Foundation
import XCTest
@testable import EonilGCDActor

class EonilGCDActorTests: XCTestCase {
    func testTiming() {
        let startTime = Date()
        do {
            let ch1 = GCDChannel<String>(capacity: 1024)
            let ch2 = GCDChannel<()>(capacity: 1024)
            GCDActor.spawn { s in
                s.sleep(for: 2)
                ch1.send("ABC")
            }
            GCDActor.spawn { s in
                let v = ch1.receive()
                XCTAssert(v == "ABC")
                ch2.send(())
            }
            print(Date())
            ch2.receive()
        }
        let endTime = Date()
        let waitingDuration = endTime.timeIntervalSince(startTime)
        XCTAssert(waitingDuration >= (2 - 0.001))
    }
    func testWaitingOnSend() {
        let sema = DispatchSemaphore(value: 0)
        let ch1 = GCDChannel<Int>(capacity: 0)
        GCDActor.spawn { s in
            let startTime = Date()
            ch1.send(111)
            let endTime = Date()
            let waitingDuration = endTime.timeIntervalSince(startTime)
            print(waitingDuration)
            XCTAssert(waitingDuration >= (2))
            sema.signal()
        }
        GCDActor.spawn { s in
            s.sleep(for: 3)
            let v = ch1.receive()
            XCTAssert(v == 111)
            sema.signal()
        }
        sema.wait()
        sema.wait()
    }
    func testWaitingOnReceive() {
        let sema = DispatchSemaphore(value: 0)
        let ch1 = GCDChannel<Int>(capacity: 0)
        GCDActor.spawn { s in
            s.sleep(for: 3)
            ch1.send(111)
            sema.signal()
        }
        GCDActor.spawn { s in
            let startTime = Date()
            let v = ch1.receive()
            XCTAssert(v == 111)
            let endTime = Date()
            let waitingDuration = endTime.timeIntervalSince(startTime)
            print(waitingDuration)
            XCTAssert(waitingDuration >= (2))
            sema.signal()
        }
        sema.wait()
        sema.wait()
    }

    func testWaitingOnSendWithBuffering() {
        let sema = DispatchSemaphore(value: 0)
        let ch1 = GCDChannel<Int>(capacity: 1)
        GCDActor.spawn { s in
            let dur1 = measureDuration {
                ch1.send(111) // Channel should not block at here. Buffer up to one value.
            }
            let dur2 = measureDuration {
                ch1.send(222) // Channel must block at here.
            }
            print("dur1 = \(dur1)")
            print("dur2 = \(dur2)")
            XCTAssert(dur1 <= 0.1)
            XCTAssert(dur2 >= 2.9)
            sema.signal()
        }
        GCDActor.spawn { s in
            s.sleep(for: 3)
            let v1 = ch1.receive()
            let v2 = ch1.receive()
            XCTAssert(v1 == 111)
            XCTAssert(v2 == 222)
            sema.signal()
        }
        sema.wait()
        sema.wait()
    }
    func testWaitingOnReceiveWithBuffering() {
        let sema = DispatchSemaphore(value: 0)
        let ch1 = GCDChannel<Int>(capacity: 1)
        GCDActor.spawn { s in
            ch1.send(111)
            s.sleep(for: 6)
            ch1.send(222)
            sema.signal()
        }
        GCDActor.spawn { s in
            s.sleep(for: 3)
            let dur1 = measureDuration {
                let v = ch1.receive()
                XCTAssert(v == 111)
            }
            let dur2 = measureDuration {
                let v = ch1.receive()
                XCTAssert(v == 222)
            }
            print("dur1 = \(dur1)")
            print("dur2 = \(dur2)")
            XCTAssert(dur1 <= 0.1)
            XCTAssert(dur2 >= 2.9)
            sema.signal()
        }
        sema.wait()
        sema.wait()
    }

    func testLimit() {
        let exp = expectation(description: "Limit")
        DispatchQueue.global().async {
            do {
                // For now, maximum number of thread in a process in macOS
                // is about 512, and OS will block any trial to make
                // additional thread. Below test code should work if there
                // was no such limit, but now it's a deadlock due to this
                // limit.
                let N = 500
                let ch0 = GCDChannel<()>(capacity: 1024)
                let ch1 = GCDChannel<()>(capacity: 1024)
                for _ in 0..<N {
                    GCDActor.spawn { s in
                        ch0.receive()
                        s.sleep(for: 1)
                        ch1.send(())
                    }
                }
                for _ in 0..<N {
                    ch0.send(())
                }
                for _ in 0..<N {
                    ch1.receive()
                }
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 30, handler: { (e: Error?) in
            guard let e = e else { return }
            XCTFail("\(e)")
        })
    }


    static var allTests : [(String, (EonilGCDActorTests) -> () throws -> Void)] {
        return [
            ("testTiming", testTiming),
            ("testLimit", testLimit),
        ]
    }

}

private func measureDuration(_ f: () -> ()) -> TimeInterval {
    let startTime = Date()
    f()
    let endTime = Date()
    let waitingDuration = endTime.timeIntervalSince(startTime)
    return waitingDuration
}
