//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicEditValueViewController : UIViewController, UITextFieldDelegate {

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    @IBOutlet var valueTextField: UITextField!
    weak var characteristic: Characteristic!
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

    var peripheralViewController: PeripheralViewController?
    var valueName: String?
    
    var progressView = ProgressView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.characteristic.stringValue?[valueName] {
                self.valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditValueViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.removeObserver(self)
    }
    
    func peripheralDisconnected() {
        Logger.debug()
//        if let peripheralViewController = self.peripheralViewController {
//            if peripheralViewController.peripheralConnected {
//                self.present(UIAlertController.alertWithMessage("Peripheral disconnected") { action in
//                        peripheralViewController.peripheralConnected = false
//                        _ = self.navigationController?.popViewController(animated: true)
//                    }, animated:true, completion:nil)
//            }
//        }
    }

    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?)
    {
        // TODO: Use Future Callback
//    guard keyPath != nil else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }
//        switch (keyPath!, context) {
//        case("state", PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext):
//            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
//                if newState == .disconnected {
//                    DispatchQueue.main.async { self.peripheralDisconnected() }
//                }
//            }
//        default:
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let newValue = self.valueTextField.text {
            let afterWriteSuceses = { (characteristic: Characteristic) -> Void in
                self.progressView.remove()
                _ = self.navigationController?.popViewController(animated: true)
                return
            }
            let afterWriteFailed = { (error: Swift.Error) -> Void in
                self.progressView.remove()
                self.present(UIAlertController.alertOnError("Characteristic Write Error", error:error) {(action) in
                    _ = self.navigationController?.popViewController(animated: true)
                        return
                    } , animated:true, completion:nil)
            }
            self.progressView.show()
            if let valueName = self.valueName {
                if var values = self.characteristic.stringValue {
                    values[valueName] = newValue
                    let write = characteristic.write(string: values, timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(completion: afterWriteSuceses)
                    write.onFailure(completion: afterWriteFailed)
                } else {
                    let write = characteristic.write(data: newValue.dataFromHexString(), timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(completion: afterWriteSuceses)
                    write.onFailure(completion: afterWriteFailed)
                }
            } else {
                Logger.debug("VALUE: \(newValue.dataFromHexString())")
                let write = characteristic.write(data: newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                write.onSuccess(completion: afterWriteSuceses)
                write.onFailure(completion: afterWriteFailed)
            }
        }
        return true
    }

}
