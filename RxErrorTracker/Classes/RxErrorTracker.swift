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
 */

open class RxErrorTracker : SharedSequenceConvertibleType {
    
    public typealias E = Error?
    public typealias SharingStrategy = DriverSharingStrategy
    
    fileprivate let _lock = NSRecursiveLock()
    fileprivate let _error = Variable<E>(nil)
    fileprivate let _errorSequence: Driver<E>
    fileprivate var _resetTimer = Timer()
    fileprivate let _disposeBag = DisposeBag()
    
    public init() {
        _errorSequence = _error.asDriver()
    }
    
    /**
     Initializes an `RxErrorTracker` with a reset signal.
     
     - parameter resetSignal: an observable sequence which flushes the current error (if any) whenever it produces an element.
     */
    public init<O: ObservableType>(resetSignal: O) {
        _errorSequence = _error.asDriver()
        
        resetSignal
            .subscribe(onNext: { [unowned self] _ in
                self.resetError()
            }).addDisposableTo(_disposeBag)
    }

    /**
     Updates the `RxErrorTracker` with the specified error.
     
     It will result in the specified error being signaled to its observers
     
     - parameter error: The error that shall be signaled to the observers
     
     - parameter resetTime: An optional time interval after which the `RxErrorTracker` will flush the specified error and signal a nil object to its observers.
     */
    open func onNext(_ error: Error?, resetTime: RxSwift.RxTimeInterval? = nil) {
        
        _resetTimer.invalidate()
        
        self.safeUpdateWithError(error)
        
        if let _resetTime = resetTime {
            _resetTimer = Timer.scheduledTimer(timeInterval: _resetTime, target:self, selector: #selector(RxErrorTracker.resetError), userInfo: nil, repeats: false)
        }
    }
    
    open func asSharedSequence() -> SharedSequence<SharingStrategy, E> {
        return _errorSequence
    }
}

private extension RxErrorTracker {
    
    func trackErrorOfObservable<O: ObservableConvertibleType>(_ source: O, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<O.E> {
        
        return source.asObservable()
            .do(onNext: { [unowned self] _ in
                self.resetError()
                },onError: { [unowned self] error in
                    self.onNext(error, resetTime: resetTime)
            })
    }
    
    @objc func resetError() {
        self.onNext(nil)
    }
    
    func safeUpdateWithError(_ error: Error?) {
        _lock.lock()
        
        /**
         Prevents consecutive nil signals
         */
        guard !(error == nil && _error.value == nil) else {return}
        
        _error.value = error
        _lock.unlock()
    }
}

public extension ObservableConvertibleType {
    
    /**
     Enables monitoring of an observable sequence.
     
     If the sequence errors out, the specified `errorTracker` gets updated with the error and signals it to its observers

     - parameter errorTracker: The `RxErrorTracker` which will start monitoring the sequence.
     
     - parameter resetTime: An optional time interval after which the `errorTracker` will flush any error and signal a nil object to its observers.
     
     - returns: Returns an observable which is already being monitored by the `errorTracker`
     */
    func trackError(_ errorTracker: RxErrorTracker, resetTime: RxSwift.RxTimeInterval? = nil) -> Observable<E> {
        return errorTracker.trackErrorOfObservable(self, resetTime: resetTime)
    }
}
