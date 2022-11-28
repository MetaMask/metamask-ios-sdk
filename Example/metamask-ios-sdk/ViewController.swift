//
//  ViewController.swift
//  metamask-ios-sdk
//
//  Created by Mpendulo Ndlovu on 11/14/2022.
//  Copyright (c) 2022 Mpendulo Ndlovu. All rights reserved.
//

import UIKit
import SwiftUI
import metamask_ios_sdk

class ViewController: UIViewController {
    private let mm = MetaMaskSDK.shared
    lazy var connectView = ConnectView(onConnect: mm.connect,
                                       onDeeplink: mm.openMetaMask)

    override func viewDidLoad() {
        super.viewDidLoad()
        let childView = UIHostingController(rootView: connectView)
        addChild(childView)
        childView.view.frame = view.bounds
        view.addSubview(childView.view)
        childView.didMove(toParent: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

