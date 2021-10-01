//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal


class ViewController: UIViewController {

    
    let audio = AudioModel()
    var sineFrequency1:Float = 1000.0
    var sineFrequency2:Float = 1000.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        audio.startProcessingSinewaveForPlayback(withFreq: 1000)
        audio.pause()
       
    }
    var playing:Bool = true
    
    @IBOutlet weak var playButton: UIButton!
    @IBAction func play(_ sender: Any) {
        
        self.audio.sineFrequency = self.sineFrequency1
        audio.play()
        Thread.sleep(forTimeInterval: 0.1)
        
        audio.pause()
        Thread.sleep(forTimeInterval: 0.001)
        
        self.audio.sineFrequency = self.sineFrequency2
        audio.play()
        Thread.sleep(forTimeInterval: 0.21)
        
        audio.pause()
        audio.sineFrequency = 0
    }
    
    
    
    @IBOutlet weak var freqLabel2: UILabel!
    @IBOutlet weak var freqLabel: UILabel!
    @IBAction func changeFrequency(_ sender: UISlider) {
        self.sineFrequency1 = sender.value
        freqLabel.text = "\(sender.value)"
    }
    
    @IBAction func changeFreq2(_ sender: UISlider) {
        self.sineFrequency2 = sender.value
        freqLabel2.text = "\(sender.value)"
    }
}

