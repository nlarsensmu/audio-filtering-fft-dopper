//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate
import CoreImage

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float] // This is different, before it was calculated everytime
    var fftData:[Float]
    var equalize:[Float]
    var setStuff:Bool = false
    
    var leftSumStandard:Float = -Float.infinity
    var rightSumStandard:Float = -Float.infinity
    
    static let FFT_WINDOW_SIZE = 100
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        equalize = Array.init(repeating: 0.0, count: 20)
    }
    
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            /* New function that runs on a time interval*/
            Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                                 selector: #selector(self.runEveryInterval),
                                 userInfo: nil,
                                 repeats: true)
        }
    }
    
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        sineFrequency = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        //self.audioManager?.outputBlock = self.handleSpeakerQueryWithSinusoid // swift for loop
        self.audioManager?.setOutputBlockToPlaySineWave(sineFrequency)
    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    func pause() {
        if let manager = self.audioManager {
            manager.pause()
        }
    }
    
    func samplingFrequency() -> Double {
        if let manager = self.audioManager {
            return manager.samplingRate
        }
        return 0.0
    }
    
    //==============================================
    // MARK: Shared Calculations
    func getFreqIndex(freq:Float) -> Int {
        if let manager = self.audioManager {
            let fs = manager.samplingRate
            let df = fs/(Double(BUFFER_SIZE))
            return Int(Double(freq)/df)
        }
        return 0
    }
    
    //==============================================
    // MARK: Module 2 Calculation
    func getWindowIndices(freq:Float, windowSize:Int) -> (Int, Int) {
        let targetIndex:Int = getFreqIndex(freq: freq)
        let halfWindow:Int = windowSize/2
        return (targetIndex-halfWindow, targetIndex+halfWindow)
    }
    
    // Set up left/rightSumStandards
    // If this function ends up with -inf for either base, it will run again  waiting for the first good mic sample.
    func setStandardSums(windowSize:Int, displacementFromCenter:Int, freq:Float) -> Bool {
        
        let idxFreq = getFreqIndex(freq: freq)
        
        let leftLower = idxFreq-windowSize-displacementFromCenter, leftUpper = idxFreq-displacementFromCenter
        let leftArray = Array(self.fftData[(leftLower)...(leftUpper)])
        self.leftSumStandard = vDSP.sum(leftArray)
        
        let rightUpper = idxFreq+windowSize+displacementFromCenter, rightLower = idxFreq+displacementFromCenter
        let rightArray = Array(self.fftData[(rightLower)...(rightUpper)])
        self.rightSumStandard = vDSP.sum(rightArray)
        
        if self.rightSumStandard > -Float.infinity && self.leftSumStandard > -Float.infinity {
            return true
        }
        return false
    }
    
    // If Hand is moving towards the screen return 1, if away return 2, else return 0
    func determineHand(windowSize:Int, displacementFromCenter:Int, freq:Float) -> (String, Float, Float) {
        
        let indices:[Int] = windowedMaxFor(nums: fftData, windowSize: 20)
        
        let freqIdx = getFreqIndex(freq: freq)
        let topIndices = getTopIndices(indices: indices, nums: fftData)
        
        
        if topIndices[1] < freqIdx {
            return ("Left Big", fftData[topIndices[1]]/fftData[freqIdx], 0.0)
        }
        if topIndices[1] < freqIdx {
            return ("Right Big",0.0, fftData[topIndices[1]]/fftData[freqIdx])
        }
        
        return ("", 0,0)
            
    }
    
    
    //==========================================
    // MARK: Private Properties
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
    
    
    //==========================================
    // MARK: Private Methods
    
    //==========================================
    // MARK: Model Callback Methods
    @objc
    private func runEveryInterval(){
        
        if inputBuffer != nil { /* If it is not nill, some float data has been added to the array */
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            // now take equalized FFT
            let width:Int = BUFFER_SIZE/2/20 // The width of each segmentZE: \(BUFFER_SIZE)")
            for i in 0...19 {
                let start:Int = i*width, end = (i*width + width) - 1

                self.equalize[i] = vDSP.maximum(fftData[start...end])
            }
        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    var sineFrequency:Float = 0.0 {
        didSet {
            if let manager = self.audioManager {
                manager.sineFrequency = sineFrequency
            }
        }
    }
    
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    private func handleSpeakerQueryWithSinusoid(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        // while pretty fast, this loop is still not quite as fast as
        // writing the code in c, so I placed a function in Novocaine to do it for you
        // use setOutputBlockToPlaySineWave() in Novocaine
        if let arrayData = data{
            var i = 0
            while i<numFrames{
                arrayData[i] = sin(phase)
                phase += phaseIncrement
                if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                i+=1
            }
        }
    }
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    // Returns indicies of peaks in any order
    func windowedMaxFor(nums:[Float], windowSize:Int) -> [Int] {
          var maxLength = 0
          var max = nums[0]
          var maxIndicies: [Int] = [Int].init()
          for i in 0...nums.count - windowSize - 1{
              if let currMax = nums[i...i+windowSize].max(){
                  if currMax == max{
                      max = currMax
                      maxLength += 1
                      if (maxLength == windowSize){
                          maxIndicies.append(i - windowSize + 1)
                      }
                  }
                  else{
                      maxLength = 0
                      max = currMax
                  }
              }
          }
        return maxIndicies
    }
    
    // gets the max two values nums[indicies]
    func getTopIndices(indices:[Int], nums:[Float]) -> [Int]{
        var maxIndex1 = indices[0]
        var maxIndex2 = indices[0]
        var returnIndices = [Int].init(repeating: 0, count: 2)
        if indices.count == 1{
            return returnIndices
        }
        if nums[indices[1]] > nums[maxIndex1] {
            maxIndex1 = indices[1]
        }
        else {
            maxIndex2 = indices[1]
        }
        for i in 2...indices.count - 1{
            //new number is greater than both
            if nums[indices[i]] > nums[maxIndex1]{
                maxIndex2 = maxIndex1
                maxIndex1 = indices[i]
            }
            //just greate than the second
            else if nums[indices[i]] > nums[maxIndex2]{
                maxIndex2 = indices[i]
            }
        }
        returnIndices[0] = maxIndex1
        returnIndices[1] = maxIndex2
        
        return returnIndices
    }
    
    
    // MARK: Debuggin methods
    func printFftAsPoints() {
        for i in 0..<fftData.count {
            print(String(format: "(%d, %lf)", i, fftData[i]))
        }
    }


}
