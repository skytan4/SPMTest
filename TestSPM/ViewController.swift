//
//  ViewController.swift
//  TestSPM
//
//  Created by Skyler Tanner on 4/30/21.
//

import UIKit
import OHHTTPStubs
import OHHTTPStubsSwift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        stub(condition: isHost("mywebservice.com")) { _ in
          // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
          let stubPath = OHPathForFile("wsresponse.json", type(of: self))
          return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
        }
    }


}

