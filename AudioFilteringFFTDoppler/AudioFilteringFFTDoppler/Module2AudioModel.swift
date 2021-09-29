//
//  Module2AudioModel.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/28/21.
//

import Foundation
import Accelerate
import CoreImage

class Module2AudioModel {
    
    // MARK: Properties
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float] // This is different, before it was calculated everytime
    var fftData:[Float]
    var fftDataPositive:[Float]
    var setStuff:Bool = false
    var debugging:Bool = false
    private var leftBaseline:Float = 0.0
    private var rightBaseline:Float = 0.0
    private var baselineCount = 0
    
    // Members set in constructor
    private var BUFFER_SIZE:Int
    private var sineFreq:Float
    private var windowSize:Int
    private var displacementFromCenter:Int
    
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
    init(buffer_size:Int, frequency:Float, window:Int, displace:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        fftDataPositive = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        sineFreq = frequency
        windowSize = window
        displacementFromCenter = displace
    }
    
    
    func getFreqIndex(freq:Float) -> Int {
        if let manager = self.audioManager {
            let fs = manager.samplingRate
            let df = fs/(Double(BUFFER_SIZE))
            return Int(Double(freq)/df)
        }
        return 0
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
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        self.sineFreq = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        //self.audioManager?.outputBlock = self.handleSpeakerQueryWithSinusoid // swift for loop
        self.audioManager?.setOutputBlockToPlaySineWave(sineFreq)
    }
    
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
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
            
            // Force fftData to be positive
            let minValue = vDSP.minimum(fftData)
            if minValue < 0 {
                print(minValue)
                fftDataPositive = vDSP.add(-minValue, fftData)
            }
        }
    }
    //==============================================
    // MARK: Module 2 Calculation
    func getWindowIndices(freq:Float, windowSize:Int) -> (Int, Int) {
        let targetIndex:Int = getFreqIndex(freq: freq)
        let halfWindow:Int = windowSize/2
        return (targetIndex-halfWindow, targetIndex+halfWindow)
    }

    func baselinesSet() -> Bool {
        return baselineCount >= 5
    }
    // Set up left/rightSumStandards
    // If this function ends up with -inf for either base, it will run again  waiting for the first good mic sample.
    func setBaselines() -> (Float, Float){
        
        let freqIdx = getFreqIndex(freq: sineFreq)
        // zoomed in FFT
        let leftSubSet = Array(fftDataPositive[freqIdx-displacementFromCenter-windowSize..<freqIdx-displacementFromCenter])
        let rightSubSet = Array(fftDataPositive[freqIdx+displacementFromCenter+1...freqIdx+displacementFromCenter+windowSize])
        
        let leftMean = vDSP.mean(leftSubSet)
        let rightMean = vDSP.mean(rightSubSet)
        
        if leftMean > -Float.infinity && rightMean > -Float.infinity && leftMean != 0 && rightMean != 0 {
            self.leftBaseline += (leftMean/Float(5.0))
            self.rightBaseline += (rightMean/Float(5.0))
            self.baselineCount += 1
        }
        return (self.leftBaseline, self.rightBaseline)
    }

    // If Hand is moving towards the screen return 1, if away return 2, else return 0
    // Get the max of the left and right sub arrays from the displayed frequency.
    // If that sound is abover a certian threshhold act on it.
    /*
     This will approach determing if the hand is coming with the following methodology
     1) split the FFT into 3 subsets
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
        var leftSubSet = Array(fftDataPositive[freqIdx-displacementFromCenter-windowSize..<freqIdx-displacementFromCenter])
        var rightSubSet = Array(fftDataPositive[freqIdx+displacementFromCenter+1...freqIdx+displacementFromCenter+windowSize])
        var centerSubSet = Array(fftDataPositive[freqIdx-displacementFromCenter...freqIdx+displacementFromCenter])
        
        
        if debugging {
            printArrayAsPoints(nums: leftSubSet)
            printArrayAsPoints(nums: rightSubSet)
            printArrayAsPoints(nums: centerSubSet)
            debugging = false
        }
        
        let leftMax = vDSP.maximum(leftSubSet)
        let rightMax = vDSP.maximum(rightSubSet)
        
        var handText = ""
        if leftMax > 1.2*leftBaseline{
            handText = "Away!"
        }
        else if rightMax > 1.2*rightBaseline{
            handText = "Towards!"
        }
        else {
            handText = "Unclear!"
        }
        
        return (handText, leftMax, rightMax)
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
