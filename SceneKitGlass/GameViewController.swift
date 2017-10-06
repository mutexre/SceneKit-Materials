//
//  GameViewController.swift
//  SceneKitGlass
//
//  Created by mutexre on 27/09/2017.
//  Copyright © 2017 mutexre. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ReplayKit
import SnapKit

class GameViewController: UIViewController, RPScreenRecorderDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 100)
        camera.apertureBladeCount = 6
        camera.motionBlurIntensity = 0.5
        camera.automaticallyAdjustsZRange = true
        camera.wantsHDR = true
        camera.sensorHeight = 24
        
        let environment = UIImage(named: "env.jpg")
        scene.lightingEnvironment.contents = environment
        scene.lightingEnvironment.intensity = 2.0
        scene.background.contents = environment
        
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = true
        
        scnView.backgroundColor = .black
        scnView.antialiasingMode = .multisampling4X
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        let recordButton = UIButton()
        scnView.addSubview(recordButton)
        recordButton.backgroundColor = .yellow
        recordButton.setTitleColor(.black, for: .normal)
        recordButton.setTitle("Start Recording", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording(_:)), for: .touchUpInside)
        recordButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        recordButton.isHidden = true
        
        RPScreenRecorder.shared().delegate = self
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    @objc func startRecording(_ sender: UIButton)
    {
        if RPScreenRecorder.shared().isAvailable
        {
            RPScreenRecorder.shared().startRecording { (error: Error?) -> Void in
                if error == nil {
                    print("Recording started")
                    
                    sender.removeTarget(self, action: #selector(self.startRecording(_:)), for: .touchUpInside)
                    sender.addTarget(self, action: #selector(self.stopRecording(_:)), for: .touchUpInside)
                    sender.setTitle("Stop Recording", for: .normal)
                    sender.setTitleColor(.red, for: .normal)
                }
                else {
                    print("Unable to start recording")
                }
            }
        }
        else {
            print("Screen recording is unavailable")
        }
    }

    @objc func stopRecording(_ sender: UIButton)
    {
        RPScreenRecorder.shared().stopRecording { (previewController: RPPreviewViewController?, error: Error?) -> Void in
            if previewController != nil
            {
                let alertController = UIAlertController(title: "Recording", message: "Do you wish to discard or view your gameplay recording?", preferredStyle: .alert)
                
                let discardAction = UIAlertAction(title: "Discard", style: .default) { (action: UIAlertAction) in
                    RPScreenRecorder.shared().discardRecording { () -> Void in
                        // Executed once recording has successfully been discarded
                    }
                }
                
                let viewAction = UIAlertAction(title: "View", style: .default, handler: { (action: UIAlertAction) -> Void in
                    self.present(previewController!, animated: true, completion: nil)
                })
                
                alertController.addAction(discardAction)
                alertController.addAction(viewAction)
                
                self.present(alertController, animated: true, completion: nil)
                
                sender.removeTarget(self, action: #selector(self.stopRecording(_:)), for: .touchUpInside)
                sender.addTarget(self, action: #selector(self.startRecording(_:)), for: .touchUpInside)
                sender.setTitle("Start Recording", for: .normal)
                sender.setTitleColor(.blue, for: .normal)
            } else {
                // Handle error
            }
        }
    }
    
    public func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        print("Screen recorder did stop recording (error: \(error.debugDescription)")
    }
    
    public func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        print("Screen recording did change availability")
    }
}
