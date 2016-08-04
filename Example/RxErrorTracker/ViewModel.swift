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
    var name: String?
    var age: Int?
    
    init(name: String?, age: Int?) {
        self.name = name
        self.age = age
    }
}

enum Error: ErrorType {
    case FetchDataFailed
}

enum ErrorBannerState {
    case NilUserName
    case NilUserAge
    case ServerError(error: ErrorType?)
    case Hidden
}

class ViewModel {
    
    typealias Data = AnyObject?
    
    var errorBannerVisibilityUpdate: Driver<Bool>
    var errorBannerMessageUpdate: Driver<String>
    
    private let nameNilErrorTracker = RxErrorTracker()
    private let ageNilErrorTracker = RxErrorTracker()
    private let fetchDataErrorTracker = RxErrorTracker()
    private let disposeBag = DisposeBag()
    
    init() {
        let errorBannerStateUpdate: Driver<ErrorBannerState> = Driver.combineLatest(
            nameNilErrorTracker,
            ageNilErrorTracker,
            fetchDataErrorTracker) {($0, $1, $2)}
            .map { ( nameNilError, ageNilError, fetchDataError) -> ErrorBannerState in
                if nameNilError != nil {
                    return .NilUserName
                } else if ageNilError != nil {
                    return .NilUserAge
                } else if let _fetchDataError = fetchDataError {
                    return .ServerError(error: _fetchDataError)
                } else {
                    return .Hidden
                }
            }
        
        errorBannerMessageUpdate = errorBannerStateUpdate
            .map { state -> String in
                switch state {
                case .NilUserName:
                    return "Name cannot be nil!!"
                case .NilUserAge:
                    return "Age cannot be nil!!"
                case .ServerError(_):
                    return "Failed trying to fetch data!!"
                case .Hidden:
                    return ""
                }
            }
        
        errorBannerVisibilityUpdate = errorBannerStateUpdate
            .map { state -> Bool in
                switch state {
                case .Hidden:
                    return false
                default:
                    return true
                }
            }
    }
    
    func refresh() {
        let user = User(name: "Bruno", age: nil)
        fetchSomeData(withUser: user)
            .trackError(fetchDataErrorTracker)
            .trackError(nameNilErrorTracker, resetTime: 4, failWhenNotMet: user.name != nil)
            .trackError(ageNilErrorTracker, resetTime: 4, failWhenNotMet: user.age != nil)
            .subscribe()
            .addDisposableTo(disposeBag)
    }
}

private extension ViewModel {
    
    func fetchSomeData(withUser user: User) -> Observable<Data?> {
        return Observable.error(Error.FetchDataFailed)
//        return Observable.just(Data())
    }
}
