# Audio Filtering FFT Dopper
This is the project for Lab 2 of Moble Sensing and Learning. The goal of this lab is to demonstrate skills with using the FFT and sound processing.

## Module 1
### Peak Finding

### Interpolation

### Math behind buffer size

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
