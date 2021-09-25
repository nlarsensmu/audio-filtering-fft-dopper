//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    
    // MARK: Properties
    private var BUFFER_SIZE:Int
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float] // This is different, before it was calculated everytime
    var fftData:[Float]
    var equalize:[Float]
    var verbose:Bool = true
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        equalize = Array.init(repeating: 0.0, count: 20)
    }
    
    func startProcessingAudioFileForPlayback(withFps:Double) {
        if let manager = self.audioManager, let fileReader = self.fileReader {
            manager.outputBlock = self.handleSpeakerWithAudioFile
            fileReader.play()
        }
        Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                             selector: #selector(self.runEveryInterval),
                             userInfo: nil,
                             repeats: true)
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
    private lazy var fileReader:AudioFileReader? = {
        if let url = Bundle.main.url(forResource: "satisfaction", withExtension: "mp3") {
            var tmpFileReader:AudioFileReader? = AudioFileReader.init(audioFileURL: url, samplingRate: Float(audioManager!.samplingRate), numChannels: audioManager!.numInputChannels)
            
            tmpFileReader!.currentTime = 0.0
            print("Audio file successfully loaded for \(url)")
            return tmpFileReader
        }else {
            print("Could not initilize audio input file")
            return nil
        }
    }()
    
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
//                self.equalize[i] = fftData[start]
//                var max:Float = fftData[start]
//                for val in fftData[start...end] {
//                    if val > max {
//                        max = val
//                    }
//                }
            }
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            verbose = false
        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    private func handleSpeakerWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        if let file = self.fileReader {
            file.retrieveFreshAudio(data, numFrames: numFrames, numChannels: numChannels)
            self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
        }
    }
    
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
    func getTopIndices(indices:[Int], nums:[Float]) -> [Int]{
        var maxIndex1 = indices[0]
        var maxIndex2 = indices[0]
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
        var returnIndices = [Int].init(repeating: 0, count: 2)
        returnIndices[0] = maxIndex1
        returnIndices[1] = maxIndex2
        
        return returnIndices
    }
}
