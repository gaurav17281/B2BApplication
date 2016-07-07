//
//  ViewController.swift
//  AppThree
//
//  Created by Gaurav Arora on 7/7/16.
//  Copyright © 2016 Gaurav Arora. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var appIdentifierTV: UITextView!
    @IBOutlet weak var appNameTV: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAppName()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateAppName() {
        let mainBundle:NSBundle = NSBundle.mainBundle()
        appIdentifierTV.text = mainBundle.bundleIdentifier
        let infoDict:NSDictionary = mainBundle.infoDictionary!
        appNameTV.text = infoDict.objectForKey("CFBundleName")?.string;
    }
}

