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

enum TestError: Error {
    case error1
    case error2
    case error3
    case simulatedError
}

class RxErrorTracker_ExampleTests: XCTestCase {
    
    var errorTracker: RxErrorTracker!
    var resetTimer = Timer()
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        self.errorTracker = RxErrorTracker()
        self.disposeBag = DisposeBag()
    }
    
    override func tearDown() {
        resetTimer.invalidate()
        super.tearDown()
    }
    
    func testDefaultError() {
        errorTracker.drive(onNext: { error in
            XCTAssertNil(error)
        }).addDisposableTo(disposeBag)
    }
    
    func testOnNext() {
        var currentError: Error? = nil
        
        errorTracker.drive(onNext: { error in
            currentError = error
        }).addDisposableTo(disposeBag)
        
        XCTAssertNil(currentError)
        
        errorTracker.onNext(TestError.error1)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .error1))
        
        errorTracker.onNext(TestError.error3)
        errorTracker.onNext(TestError.error2)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .error2))
    }
    
    func testDistictNils() {
        var nextCounter = 0
        
        errorTracker.drive(onNext: { error in
            nextCounter += 1
        }).addDisposableTo(disposeBag)
        
        XCTAssertTrue(nextCounter == 1)
        
        errorTracker.onNext(TestError.error1)
        
        XCTAssertTrue(nextCounter == 2)
        
        errorTracker.onNext(nil)
        
        XCTAssertTrue(nextCounter == 3)
        
        errorTracker.onNext(nil)
        errorTracker.onNext(nil)
        errorTracker.onNext(nil)
        
        // Should throttle consecutive nils. So counter is still 3
        XCTAssertTrue(nextCounter == 3)
        
        errorTracker.onNext(TestError.error2)
        
        XCTAssertTrue(nextCounter == 4)
    }
    
    func testResetTime() {
        var currentError: Error? = nil
        let resetTime: RxSwift.RxTimeInterval = 2
        let expectation = self.expectation(description: "Error should be nil after reset time as passed")
        
        errorTracker.drive(onNext: { error in
            currentError = error
        }).addDisposableTo(disposeBag)
        
        XCTAssertNil(currentError)
        
        errorTracker.onNext(TestError.error1, resetTime: resetTime)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .error1))
        
        let delay = DispatchTime.now() + Double(Int64(resetTime * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay) {
            XCTAssertNil(currentError)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testTrackError() {
        var expectedErrors = [Error?]()
        
        errorTracker.drive(onNext: { error in
            expectedErrors.append(error)
        }).addDisposableTo(disposeBag)
        
        // expectedErrors should be populated with the initial (nil) value
        XCTAssertTrue(expectedErrors.count == 1)
        XCTAssertNil(expectedErrors[0])
        
        simulateObservable()
            .trackError(errorTracker)
            .subscribe()
            .addDisposableTo(disposeBag)
        
        XCTAssertTrue(expectedErrors.count == 2)
        XCTAssertNil(expectedErrors[0])
        XCTAssertTrue(TestError.error(expectedErrors[1], isTestError: .simulatedError))
    }
    
    func testResetBySignal() {
        let resetSignal = PublishSubject<Void>()
        let resetableErrorTracker = RxErrorTracker(resetSignal: resetSignal)
        var currentError: Error? = TestError.error1
        
        resetableErrorTracker.drive(onNext: { error in
            currentError = error
        }).addDisposableTo(disposeBag)
        
        XCTAssertNil(currentError)
        
        resetableErrorTracker.onNext(TestError.error1)
        
        XCTAssertTrue(TestError.error(currentError, isTestError: .error1))
        
        resetSignal.onNext()
        
        XCTAssertNil(currentError)
    }
}

private extension RxErrorTracker_ExampleTests {
    
    func simulateObservable() -> Observable<AnyObject?> {
        return Observable.error(TestError.simulatedError)
    }
}

extension TestError {
    static func error(_ error: Error?, isTestError testError: TestError) -> Bool {
        guard let _error = error as? TestError else {return false}
        switch _error {
        case testError: return true
        default: return false
        }
    }
}
