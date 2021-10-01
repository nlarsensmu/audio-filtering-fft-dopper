//
//  HandViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/24/21.
//

import UIKit

class HandViewController: UIViewController {
    
    var debugging:Bool = false
    
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 2048*2
        static let MIN_FREQ:Float = 10.0
        static let MAX_FREQ:Float = 15.0
        static let FFT_WINDOW_SIZE:Int = 100
    }
    struct Module2Constants {
        static let windowSize = 50
        
        static let displacementFromCenter = 5
    }
    
    let fftWindow = 1000
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    
    @IBOutlet weak var handLabel: UILabel!
    var handText:String = "" {
        didSet {
            DispatchQueue.main.async {
                self.handLabel.text = self.handText
            }
        }
    }
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var leftBaselineLabel: UILabel!
    @IBOutlet weak var rightBaseLineLabel: UILabel!
    
    var freq:Float?
    var percentage:Float?
    var audioModel:Module2AudioModel?
    var hideDebug:Bool = false
    var showSoundGraph:Bool = false
    var showZoomedGraph:Bool = false
    var showFFTGraph:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let f = freq, let p = self.percentage {
            self.audioModel = Module2AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE,
                                                frequency: f,
                                                window: Module2Constants.windowSize,
                                                displace: Module2Constants.displacementFromCenter,
                                                percentage: p)
        }
        if hideDebug {
            hideDebugging()
        }
        
        if showFFTGraph {
            graph?.addGraph(withName: "fft_full",
                            shouldNormalize: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
        }
        
        if showZoomedGraph {
            graph?.addGraph(withName: "fft",
                            shouldNormalize: true,
                            numPointsInGraph: 100)
        }
        
        if showSoundGraph {
            graph?.addGraph(withName: "time",
                            shouldNormalize: false,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
        }
        
        if let model = self.audioModel {
            if let f = self.freq {
                model.startProcessingSinewaveForPlayback(withFreq: f)
            }
            model.startMicrophoneProcessing(withFps: 10)
            model.play()
            
            let seconds = 0.5
            
            Thread.sleep(forTimeInterval: seconds)
            
            Timer.scheduledTimer(timeInterval: 0.05, target: self,
                selector: #selector(self.updateGraph),
                userInfo: nil,
                repeats: true)
        }
        
        // Do any additional setup after loading the view.
    }
    
    
    func hideDebugging() {
        leftLabel.isHidden = true
        rightLabel.isHidden = true
        leftBaselineLabel.isHidden = true
        rightBaseLineLabel.isHidden = true
    }
    
    // The first time, this will just get the standards and the rest of the time it will apply the change in those
    @objc
    func updateGraph(){
        
        if let model = audioModel {
            // take the first 5 (non -infty) samples as a baseline
            if !model.baselinesSet() {
                let baselines = model.setBaselines()
                DispatchQueue.main.async {
                    self.leftBaselineLabel.text = String(format: "%f", baselines.0)
                    self.rightBaseLineLabel.text = String(format: "%f", baselines.1)
                }
                return
            }
            
            if let f = freq {
                let range = model.getWindowIndices(freq: f, windowSize: AudioConstants.FFT_WINDOW_SIZE)
                let subset:[Float] = Array(model.fftData[range.0...range.1])
                
                if showZoomedGraph {
                    self.graph?.updateGraph(
                        data: subset,
                        forKey: "fft"
                    )
                }
                
                let handData = model.determineHand(windowSize:Module2Constants.windowSize,
                                                            displacementFromCenter:Module2Constants.displacementFromCenter,
                                                            freq:f)
                DispatchQueue.main.async {
                    self.handText = handData.0
                    self.leftLabel.text = String(format: "%lf", handData.1)
                    self.rightLabel.text = String(format: "%lf", handData.2)
                }
            }
            if showFFTGraph {
                self.graph?.updateGraph(
                    data: model.fftData,
                    forKey: "fft_full"
                )
            }
            if showSoundGraph {
                self.graph?.updateGraph(
                    data: model.timeData,
                    forKey: "time"
                )
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let model = audioModel {
            model.pause()
        }
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let model = audioModel {
            model.pause()
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        if let model = audioModel {
            model.stopProcessingSinewaveForPlayback()
            
        }
    }
    

}
