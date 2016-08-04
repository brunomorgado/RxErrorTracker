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
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var errorBannerTopConstraint: NSLayoutConstraint!
    
    let disposeBag = DisposeBag()
    var viewModel = ViewModel()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.errorBannerVisibilityUpdate
            .driveNext { [unowned self] visible in
                self.errorBannerTopConstraint.constant = visible ? 0 : -kErrorBannerHeight
                UIView.animateWithDuration(0.4, animations: {
                    self.view.layoutIfNeeded()
                })
            }.addDisposableTo(disposeBag)
        
        viewModel.errorBannerMessageUpdate
            .driveNext { [unowned self] errorMessage in
                self.messageLabel.text = errorMessage
            }.addDisposableTo(disposeBag)
    }
    
    // User actions

    @IBAction func didTapButton(sender: AnyObject) {
        viewModel.refresh()
    }
}
