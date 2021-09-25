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
    @IBOutlet weak var lockedLabel: UILabel!
    @IBAction func unlockButton(_ sender: Any) {
        DispatchQueue.main.async {
            self.lockedLabel.text = "Unlocked"
            self.locked = false
        }
    }
    
    //MARK: Setup
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024
        static let AUDIO_PROCESSING_HERTZ = 100.0
        static let LOCKING_ITERATION_NUMBERS = 30
        static let WINDOW_SIZE = 5
        static let AMOUNT_KEPT_MAXES = 10
    }
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    var currentIndex = 0
    var max1: [Int] = [Int].init(repeating: -999999, count: AudioConstants.AMOUNT_KEPT_MAXES)
    var max2: [Int] = [Int].init(repeating: -999999, count: AudioConstants.AMOUNT_KEPT_MAXES)
        
    // Old method
    var lastMaxIndex1 = -1
    var lastMaxIndex2 = -1
    var noChangeCount = 0
    
    var locked:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

        
        
        graph?.addGraph(withName: "time",
                        shouldNormalize: false,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
        
        
        audio.startMicrophoneProcessing(withFps: AudioConstants.AUDIO_PROCESSING_HERTZ)
        audio.play()
        
        Timer.scheduledTimer(timeInterval: 1/AudioConstants.AUDIO_PROCESSING_HERTZ, target: self,
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
        let indicies = audio.windowedMaxFor(nums: audio.fftData, windowSize: AudioConstants.WINDOW_SIZE)
        let peaks = audio.getTopIndices(indices: indicies, nums: audio.fftData)
        if !self.locked {
            DispatchQueue.main.async {
                if let peak1:Int = peaks[0] as Int?,
                   let peak2:Int = peaks[1] as Int?{
                    
                    self.hz1.text = String(peak1) + "__" +  String(self.audio.fftData[peak1])
                    self.hz2.text = String(peak2) + "__" +  String(self.audio.fftData[peak2])
                }
            }
        }
        
        //add to the arrays we've made
        self.max1[self.currentIndex] = peaks[0]
        self.max2[self.currentIndex] = peaks[1]
        currentIndex += 1
        if currentIndex == AudioConstants.AMOUNT_KEPT_MAXES{
            currentIndex = 0
        }
        var max1MatchCount = 0
        for max in max1 {
            if peaks[0] == max{
                max1MatchCount += 1
            }
        }
        var max2MatchCount = 0
        for max in max2 {
            if peaks[1] == max{
                max2MatchCount += 1
            }
        }
        
        if max1MatchCount >= Int(Float(AudioConstants.AMOUNT_KEPT_MAXES) * 0.5) && max2MatchCount >= Int(Float(AudioConstants.AMOUNT_KEPT_MAXES) * 0.5) {
            self.locked = true
            self.lockedLabel.text = "Locked"
        }
        /*
        if peaks[0] != peaks[1] {
            if peaks[0] == self.lastMaxIndex1 && peaks[1] == self.lastMaxIndex2 && self.locked == false{
                self.noChangeCount += 1
                if noChangeCount == AudioConstants.LOCKING_ITERATION_NUMBERS{
                    self.locked = true
                }
            }
            else{
                self.lastMaxIndex1 = peaks[0]
                self.lastMaxIndex2 = peaks[1]
                self.noChangeCount = 0
            }
        }*/
        
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
