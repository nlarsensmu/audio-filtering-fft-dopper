//
//  HandViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/24/21.
//

import UIKit

class HandViewController: UIViewController {
    
    var debugging:Bool = true
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 2048*2
        static let MIN_FREQ:Float = 10.0
        static let MAX_FREQ:Float = 15.0
        static let FFT_WINDOW_SIZE:Int = 100
    }
    let fftWindow = 1000
    let audioModel = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    var maxLeft:Float = -999999.0
    var maxRight:Float = -999999.0
    
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var centerLabel: UILabel!
    
    var freq:Float?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        graph?.addGraph(withName: "fft_full",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: 100)
        
        graph?.addGraph(withName: "time",
                        shouldNormalize: false,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)

        if let f = self.freq {
            audioModel.startProcessingSinewaveForPlayback(withFreq: f)
        }
        audioModel.startMicrophoneProcessing(withFps: 10)
        audioModel.play()
        
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func buttonAction(_ sender: Any) {
        self.maxLeft = -999999.0
        self.maxRight = -999999.0
    }
    @objc
    func updateGraph(){
        // periodically, display the audio data
        
        if let f = freq {
            let range = audioModel.getWindowIndices(freq: f, windowSize: AudioConstants.FFT_WINDOW_SIZE)
            let subset:[Float] = Array(self.audioModel.fftData[range.0...range.1])
            self.graph?.updateGraph(
                data: subset,
                forKey: "fft"
            )
            
            let size = 2, dis = 2
            let idxFreq = audioModel.getFreqIndex(freq: f)
            let lowerSum = vDSP.sum(self.audioModel.fftData[(idxFreq-size)...(idxFreq-dis)])
            let higherSum = vDSP.sum(self.audioModel.fftData[(idxFreq+dis)...(idxFreq+size)])
            
            if lowerSum > maxLeft {
                maxLeft = lowerSum
            }
            if higherSum > maxRight {
                maxRight = higherSum
            }
            
            DispatchQueue.main.async {
                self.leftLabel.text = String(format: "%lf", self.maxLeft )
                self.rightLabel.text = String(format: "%lf", self.maxRight)
                self.centerLabel.text = String(format: "%lf", self.audioModel.fftData[idxFreq])
            }
        }
        self.graph?.updateGraph(
            data: self.audioModel.fftData,
            forKey: "fft_full"
        )
        self.graph?.updateGraph(
            data: self.audioModel.timeData,
            forKey: "time"
        )
        
        // Testing for summing stuff
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioModel.pause()
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
