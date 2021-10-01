//
//  Module2ViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/22/21.
//

import UIKit

class Module2ViewController: UIViewController, UITextFieldDelegate {

    //MARK: Outlets
    @IBOutlet weak var percentageTextField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var hzLabel: UILabel!
    @IBOutlet weak var hzSlider: UISlider!
    @IBOutlet weak var debugginSwitch: UISwitch!
    @IBOutlet weak var soundGraphSwitch: UISwitch!
    @IBOutlet weak var freqGraphSwitch: UISwitch!
    @IBOutlet weak var zoomGraphSwitch: UISwitch!
    
    //MARK: Properties
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 2048*2
        static let MIN_FREQ:Float = 15.0
        static let MAX_FREQ:Float = 20.0
    }
    
    var freq:Float = AudioConstants.MIN_FREQ{
        didSet {
            self.hzLabel.text = kHzString(hz: freq)
        }
    }
    
    //MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.hzSlider.minimumValue = Float(AudioConstants.MIN_FREQ)
            self.hzSlider.maximumValue = Float(AudioConstants.MAX_FREQ)
            self.hzSlider.value = AudioConstants.MIN_FREQ
            self.hzLabel.text = self.kHzString(hz: self.freq)
            self.percentageTextField.text = "0.9"
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //MARK: Actions
    @IBAction func tapGesture(_ sender: Any) {
        self.percentageTextField.resignFirstResponder()
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.freq = self.hzSlider.value
            self.hzLabel.text = self.kHzString(hz: self.freq)
        }
    }
    
    @IBAction func didCancelkeyboard(_ sender: Any) {
        self.percentageTextField.resignFirstResponder()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let vc = segue.destination as? HandViewController {
            vc.freq = self.freq * 1000
            if let p = Float(percentageTextField.text!) {
                vc.percentage = p
            }
            vc.hideDebug = !debugginSwitch.isOn
            vc.showSoundGraph = soundGraphSwitch.isOn
            vc.showZoomedGraph = zoomGraphSwitch.isOn
            vc.showFFTGraph = freqGraphSwitch.isOn
        }
    }
    
    // MARK: Helper MISC functions
    private func kHzString(hz:Float) -> String {
        return String(format: "%.2f kHz", hz)
    }
    
    // MARK: Text Field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.percentageTextField.resignFirstResponder()
        return true
    }
}
