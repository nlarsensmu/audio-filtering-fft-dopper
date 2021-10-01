//
//  Test2ViewController.swift
//  AudioLabSwift
//
//  Created by Nicholas Larsen on 10/1/21.
//  Copyright © 2021 Eric Larson. All rights reserved.
//

import UIKit

class Test2ViewController: UIViewController {

    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label1: UILabel!
    
    var sineFreq1:Float = 1000.0
    var sineFreq2:Float = 1000.0
    
    let audio = AudioModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    @IBAction func play(_ sender: Any) {
        
//        audio.startProcessingSinewaveForPlayback(withFreq: self.sineFreq2)
//        audio.startProcessingSinewaveForPlayback(withFreq: self.sineFreq1)

        audio.startProcessSinewaveForPlayback(withFreq1: sineFreq1, withFreq2: sineFreq2)
        
        audio.play()
        
        Thread.sleep(forTimeInterval: 0.5)
        
        audio.pause()
        
        
        
    }
    
    @IBAction func slider1(_ sender: UISlider) {
        self.sineFreq1 = sender.value
        label1.text = "\(sender.value)"
    }
    
    @IBAction func slider2(_ sender: UISlider) {
        self.sineFreq2 = sender.value
        label2.text = "\(sender.value)"
    }
    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
}
