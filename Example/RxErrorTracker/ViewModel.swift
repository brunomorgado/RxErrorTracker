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
    
    let nameNilErrorTracker = RxErrorTracker()
    let ageNilErrorTracker = RxErrorTracker()
    let fetchDataErrorTracker = RxErrorTracker()
    
    init() {
        let user = User()
        
        let fetch = fetchSomeData(withUser: user)
            .trackError(nameNilErrorTracker, resetTime: 5, failWhenNotMet: user.name != nil)
            .trackError(ageNilErrorTracker, resetTime: 5, failWhenNotMet: user.age != nil)
            .trackError(fetchDataErrorTracker)
        
        var errorBannerStateUpdate: Driver<ErrorBannerState> = Driver.combineLatest(
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
        
        var errorBannerMessageUpdate = errorBannerStateUpdate
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
        
        var errorBannerVisibilityUpdate = errorBannerStateUpdate
            .map { state -> Bool in
                switch state {
                case .Hidden:
                    return false
                default:
                    return true
                }
        }
    }
    
    func fetchSomeData(withUser user: User) -> Driver<Data?> {
        return Observable.error(Error.FetchDataFailed)
            .asDriver(onErrorJustReturn: nil)
        
//        return Driver.just(Data())
    }
}

class User {
    var name: String?
    var age: Int?
}
