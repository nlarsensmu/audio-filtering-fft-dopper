//
//  Module1ViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/22/21.
//

import UIKit

class Module1ViewController: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var hz1: UILabel!
    @IBOutlet weak var hz2: UILabel!
    
    //Math to justify the use of thes constants.
    
    //Minumum buffer size.
    // F_s / N = frequency resolution.  where F_s is the sampling frequency and N is the AUDIO_BUFFER_SIZE
    // We need a 6 Hz resolution and our samping frequency is 48,000
    // Therefore the minimum buffer size is 48,000 / 6 = 8,000
    
    //Maximum buffer size.
    //The phone is going to sample at 48,000 samples a second.
    // 48,000 (Samples / sec) *  (1 sec / 1,000 mil) = 48 samples / ms
    // 48 (samples / ms) * ( 200 ms / 1) = 9600 samples.
    //because 8192 is within this window we will use it without interpolating points.
    //MARK: Setup
    struct AudioConstants{
    static let AUDIO_BUFFER_SIZE = 8192*2
        static let AUDIO_PROCESSING_HERTZ = 100.0
        static let WINDOW_SIZE = 11
        static let THRESHOLD:Float = 12
    }
    let audio = Module1AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE, threshold: AudioConstants.THRESHOLD)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    var currentIndex = 0
    var noticedNoise:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

        
        
        graph?.addGraph(withName: "time",
                        shouldNormalize: false,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
        
        
        audio.startMicrophoneProcessing(withFps: 20)
        //audio.startMicrophoneProcessing(withFps: AudioConstants.AUDIO_PROCESSING_HERTZ)

        audio.play()
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
    }
    
    @objc
    func updateGraph(){
        //typical update graph functions for debugging
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
        //Update the labelsry
        
        let frequencies = audio.getTopFrequencies(windowSize: AudioConstants.WINDOW_SIZE,withInterp: true)
        
        // If the sound was above the threshold lock it in.
        
        if frequencies.2 || !noticedNoise {
            DispatchQueue.main.async {
                if frequencies.2 {
                    self.hz1.backgroundColor = UIColor.green
                    self.hz2.backgroundColor = UIColor.green
                }
                self.hz1.text = String(format: "%f", frequencies.0)
                self.hz2.text = String(format: "%f", frequencies.1)
            }
        }
        
        if frequencies.2 {
            noticedNoise = true
        }
    }
    
    @IBAction func resetLocks(_ sender: Any) {
        noticedNoise = false
        DispatchQueue.main.async {
            self.hz1.backgroundColor = UIColor.lightGray
            self.hz2.backgroundColor = UIColor.lightGray
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

}
