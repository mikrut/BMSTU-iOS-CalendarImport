//
//  ViewController.swift
//  Calendar Import
//
//  Created by Андрей on 09.08.15.
//  Copyright (c) 2015 BMSTU. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var resultsTextView : UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultsTextView.text = "Hello, world!"
        
        CalendarSaver.importGroup("РЛ1-52")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

