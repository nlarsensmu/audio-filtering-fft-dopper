//
//  Module2ViewController.swift
//  AudioFilteringFFTDoppler
//
//  Created by Nicholas Larsen on 9/22/21.
//

import UIKit

class Module2ViewController: UIViewController {

    
    @IBOutlet weak var graphView: UIView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var hzLabel: UILabel!
    @IBOutlet weak var hzSlider: UISlider!
    
    let MIN_VALUE:Float = 10.0
    let MAX_VALUE:Float = 15.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.hzSlider.minimumValue = Float(self.MIN_VALUE)
            self.hzSlider.maximumValue = Float(self.MAX_VALUE)
            self.hzSlider.value = self.MIN_VALUE
            self.hzLabel.text = String(format: "%.2lf Hz", self.MIN_VALUE)
        }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func sliderAction(_ sender: Any) {
        DispatchQueue.main.async {
            self.hzLabel.text = String(format: "%.2lf Hz", self.hzSlider.value)
        }
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
