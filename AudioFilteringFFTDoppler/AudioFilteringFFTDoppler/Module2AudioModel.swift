//
//  Module2AudioModel.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/28/21.
//

import Foundation
import Accelerate
import CoreImage

class Module2AudioModel:AudioModel {
    
    // MARK: Properties
    // the user can access these arrays at any time and plot them if they like
    var debugging:Bool = false
    private var leftBaseline:Float = 0.0
    private var rightBaseline:Float = 0.0
    private var baselineCount = 0
    private static let numberOfBaselines = 10
    
    // Members set in constructor
    private var sineFreq:Float
    private var windowSize:Int
    private var displacementFromCenter:Int
    private var percentageThreshold:Float
    
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    
    // MARK: Public Methods
    init(buffer_size:Int, frequency:Float, window:Int, displace:Int, percentage:Float) {
        // anything not lazily instatntiated should be allocated here
        sineFreq = frequency
        windowSize = window
        displacementFromCenter = displace
        percentageThreshold = percentage
        super.init(buffer_size: buffer_size)
    }
    
    // If Hand is moving towards the screen return 1, if away return 2, else return 0
    // Get the max of the left and right sub arrays from the displayed frequency.
    // If that sound is abover a certian threshhold act on it.
    /*
     This will approach determing if the hand is coming with the following methodology
     1) split the FFT into 3 Subsets
        * Left of the played frequecny, with a offset reserved for the target frequecny
        * Right fo the played frequency with a offest reserved for the target frequecny
        * The Center inbetween these
        |----------------[^---------------------*--------------------------^]------------------------|
                          ^                                                ^
        freqIdx-windowSize-centerDisplacement   ^   freq+windowSize+centerDisplacement
                                            freqIdx(the played frequency)
     
     2) Once we have those, we will ensure values are positive for easier processing
     3) Then we will find the max of the left and right, if those are within some threshold
        of the played frequency in amplitude, we will act on that information.
     */

    func determineHand(windowSize:Int, displacementFromCenter:Int, freq:Float) -> (String, Float, Float) {
        
        
        let freqIdx = getFreqIndex(freq: freq)
        // zoomed in FFT
        let leftSubset = Array(fftData[freqIdx-displacementFromCenter-windowSize..<freqIdx-displacementFromCenter])
        let rightSubset = Array(fftData[freqIdx+displacementFromCenter+1...freqIdx+displacementFromCenter+windowSize])
        let centerSubset = Array(fftData[freqIdx-displacementFromCenter...freqIdx+displacementFromCenter])
        
        
        if debugging {
            printArrayAsPoints(nums: leftSubset)
            printArrayAsPoints(nums: rightSubset)
            printArrayAsPoints(nums: centerSubset)
            debugging = false
        }
        
        let leftMax = vDSP.maximum(leftSubset)
        let rightMax = vDSP.maximum(rightSubset)
        let centerMax = vDSP.maximum(centerSubset)
        
        var handText = ""
        if (centerMax - leftMax) < percentageThreshold*leftBaseline {
            handText = "Away!"
        }
        else if (centerMax - rightMax) < percentageThreshold*rightBaseline {
            handText = "Towards!"
        }
        else {
            handText = "Unclear!"
        }
        
        return (handText, centerMax - leftMax, centerMax - rightMax)
    }
    
    func baselinesSet() -> Bool {
        return baselineCount >= Module2AudioModel.numberOfBaselines
    }
    
    // Set up left/rightSumStandards
    // If this function ends up with -inf for either base, it will run again  waiting for the first good mic sample.
    func setBaselines() -> (Float, Float){
        
        if baselinesSet() {
            return (self.leftBaseline, self.rightBaseline)
        }
        
        let freqIdx = getFreqIndex(freq: sineFreq)
        // zoomed in FFT
        let leftSubset = Array(fftData[freqIdx-displacementFromCenter-windowSize..<freqIdx-displacementFromCenter])
        let rightSubset = Array(fftData[freqIdx+displacementFromCenter+1...freqIdx+displacementFromCenter+windowSize])
        let centerMean = Array(fftData[freqIdx-displacementFromCenter...freqIdx+displacementFromCenter])
        
        let leftMax = vDSP.maximum(leftSubset)
        let rightMax = vDSP.maximum(rightSubset)
        let centerMax = vDSP.maximum(centerMean)
        
        if leftMax > -Float.infinity && rightMax > -Float.infinity && leftMax != 0 && rightMax != 0 {
            self.leftBaseline += (centerMax - leftMax)/Float(Module2AudioModel.numberOfBaselines)
            self.rightBaseline += (centerMax - rightMax)/Float(Module2AudioModel.numberOfBaselines)
            self.baselineCount += 1
        }
        return (self.leftBaseline, self.rightBaseline)
    }
    
    func samplingFrequency() -> Double {
        if let manager = self.audioManager {
            return manager.samplingRate
        }
        return 0.0
    }
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        self.sineFreq = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        //self.audioManager?.outputBlock = self.handleSpeakerQueryWithSinusoid // swift for loop
        self.audioManager?.setOutputBlockToPlaySineWave(sineFreq)
    }
    func stopProcessingSinewaveForPlayback() {
        self.audioManager?.pause()
        self.audioManager?.sineFrequency = 0
    }
    
    func getWindowIndices(freq:Float, windowSize:Int) -> (Int, Int) {
        let targetIndex:Int = getFreqIndex(freq: freq)
        let halfWindow:Int = windowSize/2
        return (targetIndex-halfWindow, targetIndex+halfWindow)
    }
    
    
    //==========================================
    // MARK: Private Methods
    
    private func getFreqIndex(freq:Float) -> Int {
        if let manager = self.audioManager {
            let fs = manager.samplingRate
            let df = fs/(Double(BUFFER_SIZE))
            return Int(Double(freq)/df)
        }
        return 0
    }
    
    //==========================================
    // MARK: Model Callback Methods
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    // MARK: Debuggin methods
    private func printArrayAsPoints(nums:[Float]) {
        for i in 0..<nums.count {
            print(String(format: "(%d, %f)", i, nums[i]))
        }
    }
    private func printFftAsPoints() {
        printArrayAsPoints(nums: fftData)
    }
}
