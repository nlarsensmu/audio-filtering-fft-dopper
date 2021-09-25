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
    @IBOutlet weak var graphView: UIView!
    
    
    //MARK: Static setup
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.graphView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)

        audio.startMicrophoneProcessing(withFps: 10.0)
        audio.play()
        
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
    }
    
    @objc
    func updateGraph(){
        let indicies = audio.windowedMaxFor(nums: audio.fftData, windowSize: 10)
        let peaks = audio.getTopIndices(indices: indicies, nums: audio.fftData)
        DispatchQueue.main.async {
            if let peak1:Int = peaks[0] as Int?,
               let peak2:Int = peaks[1] as Int?{
                self.hz1.text = String(peak1)
                self.hz2.text = String(peak2)
            }
        }
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
       )
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
