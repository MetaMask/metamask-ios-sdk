//
//  ViewController.swift
//  metamask-ios-sdk
//
//  Created by Mpendulo Ndlovu on 11/14/2022.
//  Copyright (c) 2022 Mpendulo Ndlovu. All rights reserved.
//

import UIKit
import metamask_ios_sdk

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("Private key: \(ECIES.generatePrivateKey())")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

