//
//  Module1AudioModel.swift
//  AudioFilteringFFTDoppler
//
//  Created by Steven Larsen on 9/30/21.
//

import Foundation

class Module1AudioModel: AudioModel {

    // MARK: Public Methods
    //===========================================
    
    init(buffer_size:Int, threshold:Float) {
        self.thresholdDb = threshold
        super.init(buffer_size: buffer_size)
    }
    
    // Return the to fequencies with or without interpolation, in the form of:
    // (A Hz, B Hz, A isAboveThreshold)
    func getTopFrequencies(windowSize:Int, withInterp:Bool) -> (Float, Float, Bool) {

        let allPeaks = windowedMaxFor(windowSize: windowSize)
        let peaks = getTopTwoIndices(indices: allPeaks)
        
        var samplingRate:Float = 0.0
        if let manager = audioManager {
            samplingRate = Float(manager.samplingRate)
        }
        let df = samplingRate/Float(self.BUFFER_SIZE)
        
        if withInterp {
            let interpedPeaks = interpolatePoints(indices: peaks)
            return (df*interpedPeaks.0,
                    df*interpedPeaks.1,
                    fftData[peaks.0] > self.thresholdDb)
        }
        else {
            return (df*Float(peaks.0),
                    df*Float(peaks.1),
                    fftData[peaks.0] > self.thresholdDb)
        }
    }
    
    // MARK: Private Properties
    //=========================================
    //Since this is a shared instance it is the same as the parent.
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private var thresholdDb:Float
    
    // MARK: Private Functions
    //====================================
    // Returns indicies of peaks of varying magnitude in order
    //The window only looks forward.  Meaning when we are at index i the indices we condiser are
    // i...i+windowSize.  This is slightly different than the algorithm suggested in class.
    private func windowedMaxFor(windowSize:Int) -> [Int] {
        
        var max = fftData[0]
        var maxIndex = 0
        var maxIndicies: [Int] = [Int].init()
        var repeatCount = 0

        for i in 0..<fftData.count - windowSize{
            let maxes = getMaxPoint(startIndex: i, endIndex: i + windowSize)
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
    
    //finds the top to values for an array of indices
    private func getTopTwoIndices(indices:[Int]) -> (Int, Int){
        
        if indices.count == 1 {
            return (indices[0], indices[0])
        }
        if indices.count == 0 {
            return (0,0)
        }
        var maxIndex1 = indices[0]
        var maxIndex2 = indices[0]
        if fftData[indices[1]] > fftData[maxIndex1] {
            maxIndex1 = indices[1]
        }
        else {
            maxIndex2 = indices[1]
        }
        if indices.count > 2 {
            for i in 2...indices.count - 1{
                //new number is greater than both
                if fftData[indices[i]] > fftData[maxIndex1]{
                    maxIndex2 = maxIndex1
                    maxIndex1 = indices[i]
                }
                //just greate than the second
                else if fftData[indices[i]] > fftData[maxIndex2]{
                    maxIndex2 = indices[i]
                }
            }
            
            return (maxIndex1, maxIndex2)
        }
        return (0,0)
    }
    
    //Use the standard interpolaton formula given in class to calculate
    //a theortical index where the peak may be.  This is why the return type is float
    private func interpolatePoint(idx:Int) -> Float {
        
        let f_2:Float = Float(idx)
        
        let m_1:Float = fftData[idx-1]
        let m_2:Float = fftData[idx]
        let m_3:Float = fftData[idx+1]
        
        var samplingRate:Float = 0.0
        if let manager = audioManager {
            samplingRate = Float(manager.samplingRate)
        }
        let df = samplingRate / Float(self.BUFFER_SIZE)
        let guess = f_2 + (m_1 - m_3)/(m_3 - 3*m_2 + m_1)*(df)/(2)
        return guess
    }
    
    //Call the above function for a tuple of indices.
    //Will check the bounds.
    private func interpolatePoints(indices:(Int, Int)) -> (Float, Float){
        
        var answers:(Float, Float) = (0.0, 0.0)
        
        if indices.0 > 0 && indices.0 < fftData.count - 1{
            answers.0 = interpolatePoint(idx: indices.0)
        }
        else {
            answers.0 = Float(indices.0)
        }
        
        if indices.1 > 0 && indices.1 < fftData.count - 1{
            answers.1 = interpolatePoint(idx: indices.1)
        }
        else {
            answers.1 = Float(indices.1)
        }
        return answers
    }
    
    //finds the max point of fftData with a start and end Index
    private func getMaxPoint(startIndex:Int, endIndex:Int) -> (Int, Float) {
        var a:[Float] = Array(fftData[startIndex...endIndex])
        var c: Float = .nan
        var i: vDSP_Length = 0
        let n = vDSP_Length(a.count)
        
        vDSP_maxvi(&a, 1, &c, &i, n)
        return (startIndex + Int(i), Float(c))
    }

}
