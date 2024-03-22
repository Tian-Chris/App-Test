import SwiftUI
import CoreBluetooth
import Foundation

class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    @Published var peripheralNames: [String] = []
    @Published var isConnected: Bool = false // Variable for screen transition
    @Published var characteristicValue: String? // Published variable to hold the value of the desired characteristic
    @Published var screen1: Bool = false // self explanatory
    
    override init (){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func connectToPeripheral(atIndex index: Int) {
        guard index >= 0 && index < peripherals.count else {
            print("Invalid peripheral index")
            return
        }
        
        let peripheral = peripherals[index]
        centralManager?.connect(peripheral, options: nil)
        screen1 = true
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "Unnamed")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral)")
        self.isConnected = true // Update connection status
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension BluetoothViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            var foundCharacteristic = false
            for characteristic in characteristics {
                
                //instead of searching for a uuid this instead subscribes to notifications
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    foundCharacteristic = true
                    print("Notification Found")
                }
                
            }
            if !foundCharacteristic {
                print("Not found")
                characteristicValue = "Not found" // Set published variable to indicate characteristic not found
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            print("Notification Data:")
            print(data)
            var count = 0
            for byte in data {
                print(count, terminator: ": ")
                print(byte, terminator: " ")
                count += 1
            }
        }
    }
}


struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        NavigationView {
            if bluetoothViewModel.isConnected && bluetoothViewModel.screen1 { // Condition modified
                VStack {
                    Text("Connected")
                    if let characteristicValue = bluetoothViewModel.characteristicValue {
                        Text("Characteristic Value: \(characteristicValue)")
                    }
                }
                .overlay(
                    Button(action: {
                        // Change screen1 to true when button is tapped
                        self.bluetoothViewModel.screen1 = false
                    }) {
                        Text("Change screen1 to false")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(10)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 20, trailing: 0)),
                    alignment: .bottom
                )
            } else {
                List(0..<bluetoothViewModel.peripheralNames.count, id: \.self) { index in
                    Button(action: {
                        self.bluetoothViewModel.connectToPeripheral(atIndex: index)
                    }) {
                        Text(self.bluetoothViewModel.peripheralNames[index])
                    }
                }
                .navigationTitle("Peripherals")
            }
        }
    }
}

