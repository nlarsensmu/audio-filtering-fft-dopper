//
//  Module2ViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/22/21.
//

import UIKit

class Module2ViewController: UIViewController {

    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var hzLabel: UILabel!
    @IBOutlet weak var hzSlider: UISlider!
    
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 2048*2
        static let MIN_FREQ:Float = 15.0
        static let MAX_FREQ:Float = 20.0
    }
    
    var freq:Float = AudioConstants.MIN_FREQ{
        didSet {
            self.hzLabel.text = kHzString(hz: freq)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.hzSlider.minimumValue = Float(AudioConstants.MIN_FREQ)
            self.hzSlider.maximumValue = Float(AudioConstants.MAX_FREQ)
            self.hzSlider.value = AudioConstants.MIN_FREQ
            self.hzLabel.text = self.kHzString(hz: self.freq)
        }
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    @IBAction func sliderAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.freq = self.hzSlider.value
            self.hzLabel.text = self.kHzString(hz: self.freq)
        }
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? HandViewController {
            vc.freq = self.freq * 1000
        }
    }
    
    
    // MARK: Helper MISC functions
    private func kHzString(hz:Float) -> String {
        return String(format: "%.2f kHz", hz)
    }
}
