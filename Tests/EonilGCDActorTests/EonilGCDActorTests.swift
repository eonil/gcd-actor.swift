import XCTest
@testable import EonilGCDActor

class EonilGCDActorTests: XCTestCase {
    func testTiming() {
        let startTime = Date()
        do {
            let ch1 = GCDChannel<String>()
            let ch2 = GCDChannel<()>()
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
    func testLimit() {
        DispatchQueue.global().async {
//            thread_count
        }
        let exp = expectation(description: "Limit")
        DispatchQueue.global().async {
            do {
                // For now, maximum number of thread in a process in macOS
                // is about 512, and OS will block any trial to make
                // additional thread. Below test code should work if there
                // was no such limit, but now it's a deadlock due to this
                // limit.
                let N = 500
                let ch0 = GCDChannel<()>()
                let ch1 = GCDChannel<()>()
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
