//
//  Module2ViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/22/21.
//

import UIKit

class Module2ViewController: UIViewController {

    
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var hzLabel: UILabel!
    @IBOutlet weak var hzSlider: UISlider!
    
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
        static let MIN_FREQ:Float = 10.0
        static let MAX_FREQ:Float = 10.0
    }
    var freq:Float = AudioConstants.MIN_FREQ{
        didSet {
            self.hzLabel.text = hzString(hz: freq)
        }
    }
    
    let audioModel = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.graphView)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.hzSlider.minimumValue = Float(AudioConstants.MIN_FREQ)
            self.hzSlider.maximumValue = Float(AudioConstants.MAX_FREQ)
            self.hzSlider.value = AudioConstants.MIN_FREQ
            self.hzLabel.text = String(format: "%.2lf Hz", AudioConstants.MIN_FREQ)
        }
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
        
        

        // Do any additional setup after loading the view.
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioModel.pause()
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.hzLabel.text = String(format: "%.2lf Hz", self.hzSlider.value)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Helper MISC functions
    private func hzString(hz:Float) -> String {
        return String(format: "%.2f Hz", hz)
    }
}
