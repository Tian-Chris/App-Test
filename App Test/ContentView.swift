import SwiftUI
import CoreBluetooth
import Foundation

class BluetoothViewModel: NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    @Published var isConnected: Bool = false // Variable for screen transition
    
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
    }
}

struct ContentView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
            NavigationView {
            if bluetoothViewModel.isConnected {
                Text("Connected") // Display this when connected
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

