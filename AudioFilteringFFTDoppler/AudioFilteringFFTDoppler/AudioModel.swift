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
    var debugging:Bool = false
    
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
        
        var max = nums[0]
        var maxIndex = 0
        var maxIndicies: [Int] = [Int].init()
        var repeatCount = 0

        for i in 0..<nums.count - windowSize{
            let maxes = getMaxPoint(startIndex: i, endIndex: i + windowSize, arr: nums)
            let currMax = maxes.1
            let currIndexMax = maxes.0
            //we are in a platue
            if currMax == max{
                repeatCount += 1
            }
            //We have left the platue need to add the median index
            else if repeatCount >= 2 {
                maxIndicies.append(maxIndex)
                repeatCount = 0
            }
            else{
                repeatCount = 0
                max = currMax
                maxIndex = currIndexMax
            }
                
            }
            return maxIndicies
    }
    
    // gets the max two values nums[indicies]
    func getTopIndices(indices:[Int], nums:[Float]) -> [Int]{
        
        var returnIndices = [Int].init(repeating: 0, count: 2)
        if indices.count == 1 {
            return returnIndices
        }
        if indices.count == 0 {
            return returnIndices
        }
        var maxIndex1 = indices[0]
        var maxIndex2 = indices[0]
        if nums[indices[1]] > nums[maxIndex1] {
            maxIndex1 = indices[1]
        }
        else {
            maxIndex2 = indices[1]
        }
        if indices.count > 2 {
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
        else{
            return indices
        }
    }
    
    //m_1 = fftData[i-1]
    //m_2 = fftData[i]
    //m_3 = fftData[i+1]
    func interpolateIndices(indides:[Int]) -> [Float]{
        var answers: [Float] = []
        
        var sampleingRate:Float = 0.0
        if let manager = audioManager {
            sampleingRate = Float(manager.samplingRate)
        }
        
        let df = sampleingRate / Float(self.BUFFER_SIZE)
        for i in indides{
            if(i != 0 && i != indides.count - 1){
                let f_2:Float = Float(i)
                
                let m_1:Float = fftData[i-1]
                let m_2:Float = fftData[i]
                let m_3:Float = fftData[i+1]
                
                let guess = f_2 + (m_1 - m_3)/(m_3 - 3*m_2 + m_1)*(df)/(2)
                answers.append(guess)
                
//                answers.append(Float(i) - ((fftData[i-1] - fftData[i+1])/(fftData[i+1] - 2*fftData[i] + fftData[i-1]))*(df/2))
            }
            else{
                answers.append(Float(i))
            }
        }
        return answers
    }
    
    func getMaxPoint(startIndex:Int, endIndex:Int, arr:[Float]) -> (Int, Float) {
        var max = arr[startIndex]
        var maxIndex = startIndex
        for i in startIndex + 1...endIndex{
            if arr[i] > max {
                max = arr[i]
                maxIndex = i
            }
        }
        return (maxIndex, max)
    }
    
    // MARK: Debuggin methods
    func printArrayAsPoints(nums:[Float]) {
        for i in 0..<nums.count {
            print(String(format: "(%d, %f)", i, nums[i]))
        }
    }
    func printFftAsPoints() {
        printArrayAsPoints(nums: fftData)
    }

}
