//
//  ViewController.swift
//  peripheral_iOS
//
//  Created by Leyee.H on 2019/3/4.
//  Copyright © 2019 Der1598c. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {

    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    
    let UUID_SERVICE = "A001"
    let UUID_CHARACTERISTICT = "C001"
    
    var peripheralManager: CBPeripheralManager!
    var charDictionary = [String: CBMutableCharacteristic]()
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        //check BT power(BT4.X)
        guard peripheral.state == .poweredOn else {
            //iOS will apprence warring to user.
            return
        }
        
        var service: CBMutableService
        var characteristic: CBMutableCharacteristic
        var charArray = [CBCharacteristic]()
        
        //GATT
        //setup service, characteristic
        service = CBMutableService(type: CBUUID(string: UUID_SERVICE), primary: true)
        characteristic = CBMutableCharacteristic(
            type: CBUUID(string: UUID_CHARACTERISTICT),
            properties: [.notifyEncryptionRequired, .writeWithoutResponse],
            value: nil,
            permissions: .writeEncryptionRequired
        )
        
        charArray.append(characteristic)
        charDictionary[UUID_CHARACTERISTICT] = characteristic
        
        service.characteristics = charArray
        peripheralManager.add(service)
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR:{\(#file, #function)}\n")
            print(error!.localizedDescription)
            return
        }
        
        let deviceName = "Device"
        peripheral.startAdvertising(
            [CBAdvertisementDataServiceUUIDsKey: [service.uuid],
             CBAdvertisementDataLocalNameKey: deviceName]
        )
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Strat advertise.")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
            print("Stop advertising")
        }
        
        if characteristic.uuid.uuidString == UUID_CHARACTERISTICT {
            
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        if characteristic.uuid.uuidString == UUID_CHARACTERISTICT {
            
        }
    }
    
    func sendData(_ data: Data, uuidString: String) throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        
        peripheralManager.updateValue(
            data,
            for: characteristic,
            onSubscribedCentrals: nil)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        guard let at = requests.first else {
            return
        }
        
        guard let data = at.value else {
            return
        }
        
        DispatchQueue.main.async {
            var string = String(data: data, encoding: .utf8)!
            string = "> " + string
            print(string)
            
            if self.textView.text ?? "" == "" {
                self.textView.text = string
            }else {
                self.textView.text = self.textView.text + "\n" + string
            }
        }
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBAction func sendBtn(_ sender: Any) {
        let string = textField.text
        if self.textView.text ?? "" == "" {
            self.textView.text = string
        }else {
            self.textView.text = self.textView.text + "\n" + string!
        }
        
        do {
            try sendData(string!.data(using: .utf8)!, uuidString: "C001")
            self.textField.text = ""
        } catch {
            print(error)
        }
        
        self.textField.resignFirstResponder()
    }
    
    @IBOutlet weak var mClear_Btn: UIButton!
    
    @objc func doClearTextField() {
        self.textView.text = ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let queue = DispatchQueue.global()
        peripheralManager = CBPeripheralManager(delegate: self, queue: queue)
        
        self.mClear_Btn .addTarget(self, action: #selector(doClearTextField), for: .touchUpInside)
    }

}

