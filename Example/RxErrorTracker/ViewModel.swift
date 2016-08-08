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

enum Error: ErrorType {
    case Internal
    case FetchUserFailed
    case FetchFriendsFailed
    
    var description: String {
        switch self {
        case Internal:
            return "Internal error!!"
        case FetchUserFailed:
            return "Failed fetching user!!"
        case .FetchFriendsFailed:
            return "Failed fetching friends!!"
        }
    }
}

class ViewModel {
    
    var errorBannerVisibilityUpdate: Driver<Bool>
    var errorBannerMessageUpdate: Driver<String>
    
    let sub = PublishSubject<Bool>()

    private let errorTracker = RxErrorTracker()
    private let disposeBag = DisposeBag()
    
    init() {
        errorBannerMessageUpdate = errorTracker
            .map { error -> String in
                guard let _error = error as? Error else {
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
            errorTracker.onNext(Error.Internal)
            return
        }

        fetchUserObservable(withId: _id)
            .trackError(errorTracker, resetTime: 4)
            .subscribe()
            .addDisposableTo(disposeBag)
    }
    
    func fetchFriends() {
        let user: User? = nil// User(name: "brunofc")
        
        guard let _user = user else {
            errorTracker.onNext(Error.Internal, resetTime: 3)
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
        return Observable.error(Error.FetchUserFailed)
    }
    
    func fetchFriendsObservable(withUser user: User) -> Observable<AnyObject?> {
        return Observable.error(Error.FetchFriendsFailed)
    }
}
