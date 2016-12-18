//
//  ViewController.swift
//  RxErrorTracker
//
//  Created by Bruno Morgado on 08/03/2016.
//  Copyright (c) 2016 Bruno Morgado. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

let kErrorBannerHeight: CGFloat = 150

class ViewController: UIViewController {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var errorBannerTopConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    var viewModel = ViewModel()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.errorBannerVisibilityUpdate
            .drive(onNext: { [unowned self] visible in
                self.errorBannerTopConstraint.constant = visible ? 0 : -kErrorBannerHeight
                UIView.animate(withDuration: 0.4, animations: {
                    self.view.layoutIfNeeded()
                })
            }).addDisposableTo(disposeBag)
        
        viewModel.errorBannerMessageUpdate
            .drive(onNext: { [unowned self] errorMessage in
                self.messageLabel.text = errorMessage
            }).addDisposableTo(disposeBag)
    }
    
    // User actions

    @IBAction func didTapFetchFriendsButton(_ sender: AnyObject) {
        viewModel.fetchFriends()
    }
    
    @IBAction func didTapFetchUserButton(_ sender: AnyObject) {
        viewModel.fetchUser()
    }
}
