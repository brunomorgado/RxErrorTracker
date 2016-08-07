//
//  RxErrorTracker.swift
//  RxErrorTracker
//
//  Created by Bruno Morgado on 08/03/2016.
//  Copyright (c) 2016 Bruno Morgado. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
    import RxSwift
    import RxCocoa
#endif

/**
 Maintains a sequence of errors that can be observed and pushed to.
 
 It is essentially a Variable<ErrorType?> with the option for automatic reset
 */

public class RxErrorTracker : DriverConvertibleType {
    
    public typealias E = ErrorType?
    
    private let _lock = NSRecursiveLock()
    private let _error = Variable<E>(nil)
    private let _errorSequence: Driver<E>
    private var _resetTimer = NSTimer()
    
    public init() {
        _errorSequence = _error.asDriver()
    }

    /**
     Updates the `RxErrorTracker` with the specified error.
     
     It will result in the specified error being signaled to its `observers`
     
     - parameter error: The error that shall be signaled to the `observers`
     
     - parameter resetTime: An optional time interval after which the `RxErrorTracker` will flush the specified error and signal a nil object to its `observers`.
     */
    public func updateWithError(error: ErrorType?, resetTime: RxSwift.RxTimeInterval? = nil) {
        
        _resetTimer.invalidate()
        
        self.safeUpdateWithError(error)
        
        if let _resetTime = resetTime {
            _resetTimer = NSTimer.scheduledTimerWithTimeInterval(_resetTime, target:self, selector: #selector(RxErrorTracker.resetError), userInfo: nil, repeats: false)
        }
    }
    
    public func asDriver() -> Driver<E> {
        return _errorSequence
    }
}

private extension RxErrorTracker {
    
    func trackErrorOfObservable<O: ObservableConvertibleType>(source: O, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<O.E> {
        
        return source.asObservable()
            .doOn(onNext: { [unowned self] _ in
                    self.resetError()
                },onError: { [unowned self] error in
                    self.updateWithError(error, resetTime: resetTime)
                })
    }
    
    @objc func resetError() {
        self.updateWithError(nil)
    }
    
    func safeUpdateWithError(error: ErrorType?) {
        _lock.lock()
        
        guard !(error == nil && _error.value == nil) else {return}
        
        _error.value = error
        
        _lock.unlock()
    }
}

public extension ObservableConvertibleType {
    
    /**
     Enables monitoring of the current `observable` sequence.
     
     If the sequence errors out, the specified errorTracker gets updated with the error and signals it to its `observers`

     - parameter errorTracker: The `RxErrorTracker` which will start monitoring the sequence.
     
     - parameter resetTime: An optional time interval after which the errorTracker will flush any error and signal a nil object to its `observers`.
     
     - returns: Returns the current `observable` which is already being monitored by the errorTracker
     */
    func trackError(errorTracker: RxErrorTracker, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<E> {
        return errorTracker.trackErrorOfObservable(self, resetTime: resetTime)
    }
}