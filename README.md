# RxErrorTracker

### An RxSwifty approach to error handling.

RxErrorTracker provides a clean, integrated and easy to use approach to error handling. It is based on [RxSwift](https://github.com/ReactiveX/RxSwift) and represents an observable sequence of errors Rx style. The main benefit is to enable a single point of entry for dealing with the multiple errors that applications need to handle.

[![CI Status](http://img.shields.io/travis/brunomorgado/RxErrorTracker.svg?style=flat)](https://travis-ci.org/brunomorgado/RxErrorTracker)
[![Version](https://img.shields.io/cocoapods/v/RxErrorTracker.svg?style=flat)](http://cocoapods.org/pods/RxErrorTracker)
[![License](https://img.shields.io/cocoapods/l/RxErrorTracker.svg?style=flat)](http://cocoapods.org/pods/RxErrorTracker)
[![Platform](https://img.shields.io/cocoapods/p/RxErrorTracker.svg?style=flat)](http://cocoapods.org/pods/RxErrorTracker)

## Usage

You can push new errors to the RxErrorTracker sequence via direct update or by tracking the errors of another observable sequence. If you've used the [ActivityIndicator](https://github.com/ReactiveX/RxSwift/blob/master/RxExample/RxExample/Services/ActivityIndicator.swift) example provided by [RxSwift](https://github.com/ReactiveX/RxSwift), RxErrorTracker will feel familiar.

Additionally, you can define reset times after which the RxErrorTracker will signal nil.

```swift
let disposeBag = DisposeBag()
let id: Int? = 1
        
guard let _id = id else {
    errorTracker.updateWithError(Error.Internal)
	return
}

fetchUserRequest(withId: _id)
	.trackError(errorTracker, resetTime: 5)
	.subscribe()
	.addDisposableTo(disposeBag)
```

Then you can observe the RxErrorTracker and handle the errors however you want.

```swift
let errorBannerMessageUpdate = errorTracker
   	.map { error -> String in
		guard let _error = error as? Error else {
			return ""
		}
		return _error.description
	}
        
let errorBannerVisibilityUpdate = errorTracker
	.map { error -> Bool in
		return error != nil
	}
```

You can be as granular as you need in tracking the errors. For more complex scenarios you could have multiple RxErrorTracker's and merge or combine them in order to set error priorities

```swift
errorBannerStateUpdate = Driver.combineLatest(
	noConnectionErrorTracker,
	serverAPIErrorTracker,
	internalErrorTracker) {($0, $1, $2)}
	.map { (noConnectionError, serverError, internalError) -> ErrorBannerState in

		// The order of the if clauses will define priorities

		if noConnectionError != nil {return .NoConnectionErrorBannerState}
		else if serverError != nil {return .ServerErrorBannerState(error: serverError)}
		else if internalError != nil {return .InternalErrorBannerState}

	}
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

RxErrorTracker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RxErrorTracker"
```

## Author

Bruno Morgado, brunofcmorgado@gmail.com

## License

RxErrorTracker is available under the MIT license. See the LICENSE file for more info.
