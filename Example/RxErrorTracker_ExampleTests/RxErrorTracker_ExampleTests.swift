//
//  RxErrorTracker_ExampleTests.swift
//  RxErrorTracker_ExampleTests
//
//  Created by Bruno Morgado on 07/08/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import XCTest
import RxSwift
import RxCocoa
import RxErrorTracker

enum TestError: ErrorType {
    case Error1
    case Error2
    case Error3
    case SimulatedError
}

class RxErrorTracker_ExampleTests: XCTestCase {
    
    var errorTracker: RxErrorTracker!
    var resetTimer = NSTimer()
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        self.errorTracker = RxErrorTracker()
    }
    
    override func tearDown() {
        resetTimer.invalidate()
        super.tearDown()
    }
    
    func testDefaultError() {
        errorTracker.driveNext { error in
            XCTAssertNil(error)
        }.addDisposableTo(disposeBag)
    }
    
    func testOnNext() {
        var currentError: ErrorType? = nil
        
        errorTracker.driveNext { error in
            currentError = error
        }.addDisposableTo(disposeBag)
        
        XCTAssertNil(currentError)
        
        errorTracker.onNext(TestError.Error1)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .Error1))
        
        errorTracker.onNext(TestError.Error3)
        errorTracker.onNext(TestError.Error2)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .Error2))
    }
    
    func testDistictNils() {
        var nextCounter = 0
        
        errorTracker.driveNext { error in
            nextCounter += 1
            }.addDisposableTo(disposeBag)
        
        XCTAssertTrue(nextCounter == 1)
        
        errorTracker.onNext(TestError.Error1)
        
        XCTAssertTrue(nextCounter == 2)
        
        errorTracker.onNext(nil)
        
        XCTAssertTrue(nextCounter == 3)
        
        errorTracker.onNext(nil)
        errorTracker.onNext(nil)
        errorTracker.onNext(nil)
        
        // Should throttle consecutive nils. So counter is still 3
        XCTAssertTrue(nextCounter == 3)
        
        errorTracker.onNext(TestError.Error2)
        
        XCTAssertTrue(nextCounter == 4)
    }
    
    func testResetTime() {
        var currentError: ErrorType? = nil
        let resetTime: RxSwift.RxTimeInterval = 2
        let expectation = self.expectationWithDescription("Error should be nil after reset time as passed")
        
        errorTracker.driveNext { error in
            currentError = error
            }.addDisposableTo(disposeBag)
        
        XCTAssertNil(currentError)
        
        errorTracker.onNext(TestError.Error1, resetTime: resetTime)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .Error1))
        
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(resetTime * Double(NSEC_PER_SEC)))
        dispatch_after(delay, dispatch_get_main_queue()) {
            XCTAssertNil(currentError)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testTrackError() {
        var expectedErrors = [ErrorType?]()
        
        errorTracker.driveNext { error in
            expectedErrors.append(error)
            }.addDisposableTo(disposeBag)
        
        // expectedErrors should be populated with the initial (nil) value
        XCTAssertTrue(expectedErrors.count == 1)
        XCTAssertNil(expectedErrors[0])
        
        simulateObservable()
            .trackError(errorTracker)
            .subscribe()
            .addDisposableTo(disposeBag)
        
        XCTAssertTrue(expectedErrors.count == 2)
        XCTAssertNil(expectedErrors[0])
        XCTAssertTrue(TestError.error(expectedErrors[1], isTestError: .SimulatedError))
    }
}

private extension RxErrorTracker_ExampleTests {
    
    func simulateObservable() -> Observable<AnyObject?> {
        return Observable.error(TestError.SimulatedError)
    }
}

extension TestError {
    static func error(error: ErrorType?, isTestError testError: TestError) -> Bool {
        guard let _error = error as? TestError else {return false}
        switch _error {
        case testError: return true
        default: return false
        }
    }
}
