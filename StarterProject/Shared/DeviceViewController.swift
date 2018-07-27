//
//  DeviceViewController.swift
//  SwiftStarter
//
//  Created by Stephen Schiffli on 10/20/15.
//  Copyright © 2015 MbientLab Inc. All rights reserved.
//

import UIKit
import MetaWear
import AVFoundation

class DeviceViewController: UIViewController {
    
    @IBOutlet weak var deviceStatus: UILabel!
    @IBOutlet weak var headView: headViewController!
    
    let PI : Double = 3.14159265359
    
    var device: MBLMetaWear!
    var timer : Timer?
    var startTime : TimeInterval?
    
    var playSoundsController : PlaySoundsController!
    
    var seagullX : Float = -50
    var seagullY : Float = 20
    var seagullZ : Float = -5
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        device.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions.new, context: nil)
        device.connectAsync().success { _ in
            self.device.led?.flashColorAsync(UIColor.green, withIntensity: 1.0, numberOfFlashes: 3)
            NSLog("We are connected")
        }
        loadSounds()
       
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        device.removeObserver(self, forKeyPath: "state")
        device.led?.flashColorAsync(UIColor.red, withIntensity: 1.0, numberOfFlashes: 3)
        device.disconnectAsync()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        OperationQueue.main.addOperation {
            switch (self.device.state) {
            case .connected:
                self.deviceStatus.text = "Connected";
                self.device.sensorFusion?.mode = MBLSensorFusionMode.imuPlus
            case .connecting:
                self.deviceStatus.text = "Connecting";
            case .disconnected:
                self.deviceStatus.text = "Disconnected";
            case .disconnecting:
                self.deviceStatus.text = "Disconnecting";
            case .discovery:
                self.deviceStatus.text = "Discovery";
            }
        }
    }
    
    func getFusionValues(obj: MBLEulerAngleData){
        
        let xS =  String(format: "%.02f", (obj.p))
        let yS =  String(format: "%.02f", (obj.y))
        let zS =  String(format: "%.02f", (obj.r))
    
        let x = radians((obj.p * -1) + 90)
        let y = radians(abs(365 - obj.y))
        let z = radians(obj.r)
        headView.setPointerPosition(w: 0.0, x : x, y: y, z: z)
        playSoundsController.updateAngularOrientation(abs(Float(365 - obj.y)))
        
        // Send OSC here
    }
 
    func radians(_ degree: Double) -> Double {
        return ( PI/180 * degree)
    }
    func degrees(_ radian: Double) -> Double {
        return (180 * radian / PI)
    }
    
    
    @IBAction func startPressed(sender: AnyObject) {
        
        device.sensorFusion?.eulerAngle.startNotificationsAsync { (obj, error) in
            self.getFusionValues(obj: obj!)
            }.success { result in
                print("Successfully subscribed")
            }.failure { error in
                print("Error on subscribe: \(error)")
        }
    }
    
    @IBAction func stopPressed(sender: AnyObject) {
        device.sensorFusion?.eulerAngle.stopNotificationsAsync().success { result in
            print("Successfully unsubscribed")
            }.failure { error in
                print("Error on unsubscribe: \(error)")
        }
    }
    
    func loadSounds(){
        var soundArray : [String] = []
        for index in 0...3{
            soundArray.append(String(index) + ".wav")
        }
        playSoundsController = PlaySoundsController(files: soundArray)
        
        playSoundsController.updatePosition(index: 0, position: AVAudio3DPoint(x: 0, y: 0, z: -15))
        playSoundsController.updatePosition(index: 1, position: AVAudio3DPoint(x: 7.5, y: 10, z: 7.5 * sqrt(2.0)))
        playSoundsController.updatePosition(index: 2, position: AVAudio3DPoint(x: 0, y: -2, z: 0))
        playSoundsController.updatePosition(index: 3, position: AVAudio3DPoint(x: -100, y: 10, z: -5))
        
        for sounds in soundArray.enumerated(){
            // skip seagguls
            if sounds.offset != 3 {
                playSoundsController.play(index: sounds.offset)
            }
        }
    
    }
    
    @IBAction func seagulls(_ sender: UIButton) {
        timer = Timer()
        //startTime = TimeInterval()
        let aSelector : Selector = #selector(self.moveSoundsLinearPath)
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: aSelector,     userInfo: nil, repeats: true)
        //startTime = Date.timeIntervalSinceReferenceDate
        //play seagulls here
        playSoundsController.play(index: 3)
    }
    
    func moveSoundsLinearPath(){
        
        playSoundsController.updatePosition(index: 3, position: AVAudio3DPoint(x: seagullX, y: seagullY, z: seagullZ))
        seagullX += 0.1
        if seagullX > 100.0 {
            playSoundsController.stop(index: 3)
            stopTimer()
            seagullX = -100
        }
    }
    
    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
}
