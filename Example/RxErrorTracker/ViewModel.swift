//
//  ViewModel.swift
//  RxErrorTracker
//
//  Created by Bruno Morgado on 08/03/2016.
//  Copyright (c) 2016 Bruno Morgado. All rights reserved.
//

import RxSwift
import RxCocoa
import RxErrorTracker

class User {
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

enum MyError: Error {
    case internalError
    case fetchUserFailed
    case fetchFriendsFailed
    
    var description: String {
        switch self {
        case .internalError:
            return "Internal error!!"
        case .fetchUserFailed:
            return "Failed fetching user!!"
        case .fetchFriendsFailed:
            return "Failed fetching friends!!"
        }
    }
}

class ViewModel {
    
    var errorBannerVisibilityUpdate: Driver<Bool>
    var errorBannerMessageUpdate: Driver<String>
    
    let sub = PublishSubject<Bool>()

    fileprivate let errorTracker = RxErrorTracker()
    fileprivate let disposeBag = DisposeBag()
    
    init() {
        errorBannerMessageUpdate = errorTracker
            .map { error -> String in
                guard let _error = error as? MyError else {
                    return ""
                }
                return _error.description
            }
        
        errorBannerVisibilityUpdate = errorTracker
            .map { error -> Bool in
                return error != nil
            }
    }
    
    func fetchUser() {
        let id: Int? = 1
        
        guard let _id = id else {
            errorTracker.onNext(MyError.internalError)
            return
        }

        fetchUserObservable(withId: _id)
            .trackError(errorTracker, resetTime: 4)
            .subscribe()
            .addDisposableTo(disposeBag)
    }
    
    func fetchFriends() {
        let user: User? = nil
        
        guard let _user = user else {
            errorTracker.onNext(MyError.internalError, resetTime: 4)
            return
        }
        
        fetchFriendsObservable(withUser: _user)
            .trackError(errorTracker, resetTime: 4)
            .subscribe()
            .addDisposableTo(disposeBag)
    }
}

private extension ViewModel {
    
    func fetchUserObservable(withId id: Int) -> Observable<User?> {
        return Observable.error(MyError.fetchUserFailed)
    }
    
    func fetchFriendsObservable(withUser user: User) -> Observable<AnyObject?> {
        return Observable.error(MyError.fetchFriendsFailed)
    }
}
