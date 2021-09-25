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
    
    //MARK: Setup
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024
    }
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    var lastMaxIndex1 = -1
    var lastMaxIndex2 = -1
    var noChangeCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

        
        
        graph?.addGraph(withName: "time",
                        shouldNormalize: false,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
        
        
        audio.startMicrophoneProcessing(withFps: 100.0)
        audio.play()
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
    }
    
    @objc
    func updateGraph(){
        let indicies = audio.windowedMaxFor(nums: audio.fftData, windowSize: 10)
        let peaks = audio.getTopIndices(indices: indicies, nums: audio.fftData)
        let mean = vDSP.mean(audio.fftData)
        print(mean)
        DispatchQueue.main.async {
            if let peak1:Int = peaks[0] as Int?,
               let peak2:Int = peaks[1] as Int?{
                
                self.hz1.text = String(peak1) + "__" +  String(self.audio.fftData[peak1])
                self.hz2.text = String(peak2) + "__" +  String(self.audio.fftData[peak2])
            }
        }
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
       )
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
        if peaks[0] != peaks[1] {
            if peaks[0] == self.lastMaxIndex1 && peaks[1] == self.lastMaxIndex2{
                self.noChangeCount += 1
                if noChangeCount == 3{
                    //here is where we would move to the next screen
                }
            }
            else{
                self.lastMaxIndex1 = peaks[0]
                self.lastMaxIndex2 = peaks[1]
                self.noChangeCount = 0
            }
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
