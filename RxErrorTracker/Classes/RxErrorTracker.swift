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

public enum RxErrorTrackerError: ErrorType {
    case ConditionNotMet
}

/**
 Keeps track of the error associated with the source observable.
 */

public class RxErrorTracker : DriverConvertibleType {
    public typealias E = ErrorType?
    
    private let _errorLock = NSRecursiveLock()
    private let _error = Variable<E>(nil)
    private let _errorSequence: Driver<E>
    private var _resetTimer = NSTimer()
    
    public init() {
        _errorSequence = _error.asDriver()
    }

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
    
    @objc func resetError() {
        self.updateWithError(nil)
    }
    
    func trackErrorOfObservable<O: ObservableConvertibleType>(source: O, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<O.E> {
        return source.asObservable()
            .doOnError { [unowned self] error in
                self.updateWithError(error, resetTime: resetTime)
            }
    }
    
    func safeUpdateWithError(error: ErrorType?) {
        _errorLock.lock()
        guard !(error == nil && _error.value == nil) else {return}
        _error.value = error
        _errorLock.unlock()
    }
}

public extension ObservableConvertibleType {
    
    func trackError(errorTracker: RxErrorTracker, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<E> {
        return errorTracker.trackErrorOfObservable(self, resetTime: resetTime)
    }
}