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
    private let _error = Variable<ErrorType?>(nil)
    private let _element: Driver<E>
    private let disposeBag = DisposeBag()
    
    public init() {
        _element = _error.asDriver()
    }
    
    public func trackError<O: ObservableConvertibleType>(source: O, condition: Bool, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<O.E> {
        
        self.reset()
        
        guard condition else {
            let error = RxErrorTrackerError.ConditionNotMet
            self.updateWithError(error, resetTime: resetTime)
            return Observable.error(error)
        }
        
        return source.asObservable()
            .doOn(
                onNext: { [unowned self] _ in
                    self.reset()
                },
                onError: { [unowned self] error in
                    guard !self.isConditionNotMetError(error) else {return}
                    self.updateWithError(error, resetTime: resetTime)
                })
    }
    
    public func reset() {
        self.safeUpdateWithError(nil)
    }
    
    public func asDriver() -> Driver<E> {
        return _element
    }
}

private extension RxErrorTracker {
    func updateWithError(error: ErrorType, resetTime: RxSwift.RxTimeInterval?) {
        self.safeUpdateWithError(error)
        
        if let _resetTime = resetTime {
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(_resetTime * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.reset()
            }
        }
    }
    
    func safeUpdateWithError(error: ErrorType?) {
        _errorLock.lock()
        guard !(error == nil && _error.value == nil) else {return}
        _error.value = error
        _errorLock.unlock()
    }
    
    func isConditionNotMetError(error: ErrorType?) -> Bool {
        guard let _error = error as? RxErrorTrackerError else {return false}
        switch _error {
        case .ConditionNotMet:
            return true
        }
    }
}

public extension ObservableConvertibleType {
    
    func trackError(errorTracker: RxErrorTracker) -> Observable<E> {
        return errorTracker.trackError(self, condition: true)
    }
    
    func trackError(errorTracker: RxErrorTracker, resetTime: RxSwift.RxTimeInterval) -> Observable<E> {
        return errorTracker.trackError(self, condition: true, resetTime: resetTime)
    }
    
    func trackError(errorTracker: RxErrorTracker, failWhenNotMet condition: Bool) -> Observable<E> {
        return errorTracker.trackError(self, condition: condition)
    }
    
    func trackError(errorTracker: RxErrorTracker, resetTime: RxSwift.RxTimeInterval, failWhenNotMet condition: Bool) -> Observable<E> {
        return errorTracker.trackError(self, condition: condition, resetTime: resetTime)
    }
}