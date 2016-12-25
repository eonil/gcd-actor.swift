////
////  main.swift
////  thactor-prototype-1
////
////  Created by Hoon H. on 2016/12/25.
////  Copyright © 2016 Eonil. All rights reserved.
////
//
//import Foundation
//
//final class Semaphore {
//    private let mutex = NSLock()
//    private var queue = [NSCondition]()
//    private var capacity = 0
//
//    func signal() {
//        mutex.lock()
//        if queue.count == 0 {
//            assert(capacity >= 0)
//            capacity += 1
//        }
//        else {
//            assert(capacity == 0)
//            assert(queue.count > 0)
//            let cond = queue.removeFirst()
//            cond.lock()
//            cond.signal()
//            cond.unlock()
//        }
//        mutex.unlock()
//    }
//    func wait() {
//        mutex.lock()
//        if capacity > 0 {
//            capacity -= 1
//            mutex.unlock()
//        }
//        else {
//            assert(capacity == 0)
//            let cond = NSCondition()
//            queue.append(cond)
//            mutex.unlock()
//            cond.lock()
//            cond.wait()
//            cond.unlock()
//        }
//    }
//}
//
////let sema = Semaphore()
////let sema1 = Semaphore()
////
////Thread.detachNewThread {
////    sema.wait()
////    print("AAA")
////    sema1.signal()
////    print("BBB")
////    sema1.signal()
////    print("CCC")
////    sema1.signal()
////}
////Thread.detachNewThread {
////    sleep(3)
////    sema.signal()
////}
////
////sema1.wait()
////sema1.wait()
////sema1.wait()
////print("OK")
//
//
//
//
//
//
//final class Thannel<T> {
//    private let sema = Semaphore()
//    private let mutex = NSLock()
//    private var queue = [T]()
//    func read() -> T {
//        sema.wait()
//        mutex.lock()
//        assert(queue.count > 0)
//        let v = queue.removeFirst()
//        mutex.unlock()
//        return v
//    }
//    func write(_ v: T) {
//        mutex.lock()
//        queue.append(v)
//        mutex.unlock()
//        sema.signal()
//    }
//}
//
////final class Thannel<T> {
////    private let cond = NSCondition()
////    private var waiting = false
////    private var queue = [T]()
////    private let mutex = NSLock()
////    func read() -> T {
////        cond.lock()
////        while queue.count == 0 {
////            waiting = true
////            cond.wait()
////            waiting = false
////        }
////        assert(queue.count > 0)
////        let v = queue.removeFirst()
////        cond.unlock()
////        return v
////    }
////    func write(_ v: T) {
////        cond.lock()
////        queue.append(v)
////        if waiting {
////            cond.signal()
////        }
////        cond.unlock()
////    }
////}
//
//protocol ThactorSelf {
//    func pause()
//    func sleep(for duration: TimeInterval)
//}
//protocol ThactorRef {
//    func resume()
//}
//
//enum Thactor {
//    static func spawn(_ f: @escaping (_ self: ThactorSelf) -> ()) -> ThactorRef {
//        let thactor = ThactorImpl()
//        Thread.detachNewThread {
//            thactor.DBG_pth_id = pthread_self()
//            f(thactor)
//        }
//        return thactor
//    }
//}
//private final class ThactorImpl: ThactorSelf, ThactorRef {
//    private let sema = Semaphore()
//    fileprivate var DBG_pth_id: pthread_t?
//    fileprivate init() {
//    }
//    func pause() {
//        assertSelfThread()
//        sema.wait()
//    }
//    func sleep(for duration: TimeInterval) {
//        assertSelfThread()
//        let ms = useconds_t(1_000_000 * duration)
//        let r = Darwin.usleep(ms)
//        assert(r == 0)
//    }
//    func resume() {
//        sema.signal()
//    }
//    
//    private func assertSelfThread() {
//        assert(pthread_equal(DBG_pth_id, pthread_self()) != 0, "Must be called only from the self thread.")
//    }
//}
//
////let ch1 = Thannel<()>()
////let ch2 = Thannel<()>()
////let t1 = Thactor.spawn { s in
////    ch1.read()
////    print("YYY")
////    s.sleep(for: 3)
////    ch2.write(())
////}
////let t2 = Thactor.spawn { s in
////    s.sleep(for: 3)
////    print("BBB")
////    ch1.write(())
////}
////
////ch2.read()
////print("AAA")
//
//do {
//    // For now, maximum number of thread in a process in macOS
//    // is about 512, and OS will block any trial to make
//    // additional thread. Below test code should work if there
//    // was no such limit, but now it's a deadlock due to this
//    // limit.
//    let N = 1024 * 2
//    let ch0 = Thannel<()>()
//    let ch1 = Thannel<()>()
//    for i in 0..<N {
//        Thactor.spawn { s in
//            print("A \(i)")
//            ch0.read()
//            s.sleep(for: 3)
//            ch1.write(())
//            print("B \(i)")
//        }
//    }
//    for _ in 0..<N {
//        ch0.write(())
//    }
//    for _ in 0..<N {
//        ch1.read()
//    }
//}
//
//
