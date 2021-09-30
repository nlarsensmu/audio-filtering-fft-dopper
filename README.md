# Audio Filtering FFT Dopper
This is the project for Lab 2 of Moble Sensing and Learning. The goal of this lab is to demonstrate skills with using the FFT and sound processing.

## Module 1
### Peak Finding

### Interpolation

### Math behind buffer size
We need the buffer to only contain sounds that last 200ms, i.e. We will figure out how many samples are in 200ms

```math
Fs = 48000Hz
Fs = 48kHz (how many samples in 1 ms)
48 * 200 = 9600 samples
```
So our buffer size needs to be less than 9600. We will use 8192 since it is a power of 2. With interpolation we will get the resolution we need as well.

## Module 2
Module 2 will be done in 3 phases

### Waiting phase
During this phase we start playing the audio at the desired frequency, but we let the buffer flush out a few times before we start really processing. A total of half a second is waited during this phase

### Baseline Phase
During this phase we gather the following values
* The maximum value of the FFT closely to the left of the peak
* The maximum value of the FFT closely to the right of the peak
* The maximum balue of the FFT closely in the center around the peak
Then we calculate the distance from each left and right peak to the center. This will be done 10 times, and the values will be averaged and stored as a baseline.

### Determine Hand Phase
During this phase the app will constantly determine if the a hand is mving towards or away from the phone. We will determine this by calculating the three values above on the real time data, then if the displacement is bigger than some percentage of the orignal displacement (set to 90%) then we will report on that value  appropriately.

### Debugging Guide

Top left Label: Constantly updating displacment from the max of the left window to the max of the peak window
Top right Label: Constantly updating displacment from the max of the right window to the max of the peak window
Bottom left Label: The baseline value from the loading phase for the left window
Bottom right Label: The baseline balue from the loading pahse for the right window 
