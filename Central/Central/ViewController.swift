//
//  ViewController.swift
//  Central
//
//  Created by Leyee.H on 2019/3/3.
//  Copyright © 2019 Der1598c. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    enum SendDataError: Error {
        case CharacteristicNotFound
    }
    
    var centralManager: CBCentralManager!
    var connectPeripheral: CBPeripheral!
    var charDictionary = [String: CBCharacteristic]()
    
    func isPaired() -> Bool {
        let user = UserDefaults.standard
        if let uuidString = user.string(forKey: "KEY_PERIPHERAL_UUID") {
            let uuid = UUID(uuidString: uuidString)
            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!])
            if list.count > 0 {
                connectPeripheral = list.first
                connectPeripheral.delegate = self
                return true
            }
        }
        return false
    }
    
    //1
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        
        if isPaired() {
            centralManager.connect(connectPeripheral, options: nil)
        }else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    //2
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Find BT device: \(String(describing: peripheral.name))")
        
        guard peripheral.name != nil else {
            return
        }
//        guard peripheral.name == "Device" else {
//            return
//        }
        guard peripheral.name?.range(of: "Joseph") != nil else {
            return
        }
        
        central.stopScan()
        
        let user = UserDefaults.standard
        user.set(peripheral.identifier.uuidString, forKey: "KEY_PERIPHERAL_UUID")
        user.synchronize()
        
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        
        centralManager.connect(connectPeripheral, options: nil)
    }
    
    //3
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        charDictionary = [:]
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnect")
        mScribe_Swh.setOn(false, animated: false)
    }
    
    //4
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            return
        }
        
        for service in peripheral.services! {
            connectPeripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //5
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            return
        }
        
        for characteristic in service.characteristics! {
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            print("Find: \(uuidString)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("ERROR: \(#file, #function)")
            print(error!)
            return
        }
        
        if characteristic.uuid.uuidString == "C001" {
            let data = characteristic.value! as NSData
            DispatchQueue.main.async {
                var string = String(data: data as Data, encoding: .utf8)!
                string = "> " + string
                print(string)
                
                if self.textView.text == "" {
                    self.textView.text = string
                } else {
                    self.textView.text = self.textView.text + "\n" + string
                }
            }
        }
    }
    
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType) throws {
        guard let characteristic = charDictionary[uuidString] else {
            throw SendDataError.CharacteristicNotFound
        }
        
        connectPeripheral.writeValue(
            data,
            for: characteristic,
            type: writeType
        )
    }
    
    /*
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("Data write case ERROR: \(error)")
        }
    }
     */
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var mScan_Btn: UIButton!
    @IBOutlet weak var mScribe_Swh: UISwitch!
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if(sender.isOn){
            if let char = charDictionary["C001"] {
                connectPeripheral.setNotifyValue(true, for: char)
            }
            else {
                print("Find: Can't find \"C001\"")
                sender.setOn(false, animated: false)
            }
        }
        else {
            if(connectPeripheral.state == .connected) {
//                connectPeripheral.setNotifyValue(false, for: char)
                centralManager.cancelPeripheralConnection(connectPeripheral)
            }
        }
    }
    
    @IBAction func sendClick(_ sender: Any) {
        let string = self.textField.text ?? ""
        if self.textView.text == "" {
            self.textView.text = string
        } else {
            self.textView.text = self.textView.text + "\n" + string
        }
        
        do {
            try sendData(string.data(using: .utf8)!, uuidString: "C001", writeType: .withoutResponse)
            self.textField.text = ""
        } catch {
            print(error)
        }
        
        self.textField.resignFirstResponder()
    }
    
    @objc func doScan() {
        if isPaired() {
            centralManager.connect(connectPeripheral, options: nil)
        }else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let queue = DispatchQueue.global()
        centralManager = CBCentralManager(delegate: self, queue: queue)
        
        self.mScan_Btn .addTarget(self, action: #selector(doScan), for: .touchUpInside)
    }


}

