/*
WunderLINQ Client Application
Copyright (C) 2020  Keith Conger, Black Box Embedded, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit
import CoreBluetooth

class HWSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    let bleData = BLE.shared
    let wlqData = WLQ.shared
    let keyboardHID = KeyboardHID.shared
    
    var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet weak var actionsTableView: UITableView!
    @IBOutlet weak var configButton: LocalisableButton!
    
    let cellReuseIdentifier = "hwActionCell"
    
    var actionTableLabels: [String] = [""]
    var actionTableMappingLabels: [String] = [""]
    var actionID: [Int] = []
    var selectedActionID:Int = -1

    @IBAction func configPressed(_ sender: Any) {
        if (self.peripheral != nil && self.characteristic != nil){
            let alertController = UIAlertController(
                title: NSLocalizedString("hwsave_alert_title", comment: ""),
                message: NSLocalizedString("hwsave_alert_body", comment: ""),
                preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("hwsave_alert_btn_cancel", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            let openAction = UIAlertAction(title: NSLocalizedString("hwsave_alert_btn_ok", comment: ""), style: .default) { (action) in
                if (self.configButton.tag == 0){
                    print("Resetting WLQ Config")
                    if (self.wlqData.getfirmwareVersion() != "Unknown"){
                        if (self.wlqData.getfirmwareVersion().toDouble()! >= 2.0) {
                            let command = self.wlqData.WRITE_CONFIG_CMD + self.wlqData.defaultConfig2 + self.wlqData.CMD_EOM
                            let writeData =  Data(_: command)
                            self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                        } else {
                            let command = self.wlqData.WRITE_CONFIG_CMD + self.wlqData.defaultConfig1 + self.wlqData.CMD_EOM
                            let writeData =  Data(_: command)
                            self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                        }
                    }
                } else if (self.configButton.tag == 1){
                    print("Apply WLQ Config")
                    if (self.wlqData.getfirmwareVersion().toDouble()! >= 2.0) {
                        let command = self.wlqData.WRITE_CONFIG_CMD + self.wlqData.tempConfig! + self.wlqData.CMD_EOM
                        
                        var messageHexString = ""
                        for i in 0 ..< command.count {
                            messageHexString += String(format: "%02X", command[i])
                            if i < command.count - 1 {
                                messageHexString += ","
                            }
                        }
                        print("Writing flashConfig: \(messageHexString)")
                        let writeData =  Data(_: command)
                        self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                    } else {
                        if (self.wlqData.sensitivity != self.wlqData.tempSensitivity){
                            let sensInt:Int = (Int)(self.wlqData.tempSensitivity!)
                            let sensString:String = (String)(sensInt)
                            let sensCharacters = Array(sensString)
                            let sensUInt8Array = String(sensCharacters).utf8.map{ UInt8($0) }
                            let command = self.wlqData.WRITE_SENSITIVITY_CMD + sensUInt8Array + self.wlqData.CMD_EOM
                            let writeData =  Data(_: command)
                            self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                        }
                    }
                } else if (self.configButton.tag == 2){
                    print("Set WLQ Mode")
                    if (self.wlqData.getfirmwareVersion().toDouble()! >= 2.0) {
                        var value:[UInt8] = [self.wlqData.keyMode_custom]
                        if (self.wlqData.keyMode == self.wlqData.keyMode_custom){
                            value = [self.wlqData.keyMode_default]
                        }
                        let command = self.wlqData.WRITE_MODE_CMD + value + self.wlqData.CMD_EOM
                        let writeData =  Data(_: command)
                        self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                    } else {
                        var value:[UInt8] = [self.wlqData.wheelMode_full]
                        if (self.wlqData.wheelMode == self.wlqData.wheelMode_full){
                            value = [self.wlqData.wheelMode_rtk]
                        }
                        let command = self.wlqData.WRITE_MODE_CMD + value + self.wlqData.CMD_EOM
                        let writeData =  Data(_: command)
                        self.peripheral?.writeValue(writeData, for: self.characteristic!, type: CBCharacteristicWriteType.withResponse)
                    }
                    
                }
                self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(openAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @objc func leftScreen() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppUtility.lockOrientation(.portrait)
        
        let backBtn = UIButton()
        backBtn.setImage(UIImage(named: "Left")?.withRenderingMode(.alwaysTemplate), for: .normal)
        if #available(iOS 13.0, *) {
            backBtn.tintColor = UIColor(named: "imageTint")
        }
        backBtn.addTarget(self, action: #selector(leftScreen), for: .touchUpInside)
        let backButton = UIBarButtonItem(customView: backBtn)
        let backButtonWidth = backButton.customView?.widthAnchor.constraint(equalToConstant: 30)
        backButtonWidth?.isActive = true
        let backButtonHeight = backButton.customView?.heightAnchor.constraint(equalToConstant: 30)
        backButtonHeight?.isActive = true
        self.navigationItem.title = NSLocalizedString("fw_config_title", comment: "")
        self.navigationItem.leftBarButtonItems = [backButton]
        
        actionsTableView.delegate = self
        actionsTableView.dataSource = self
        
        peripheral = bleData.getPeripheral()
        characteristic = bleData.getcmdCharacteristic()

        updateDisplay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplay()
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.actionTableLabels.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:HWSettingsTableViewCell = self.actionsTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! HWSettingsTableViewCell
        
        cell.hwActionLabel.text = self.actionTableLabels[indexPath.row]
        cell.hwActionMappingLabel.text = self.actionTableMappingLabels[indexPath.row]
        cell.actionID = self.actionID[indexPath.row]
        if(self.actionTableMappingLabels[indexPath.row] == ""){
            cell.hwActionLabel.font = cell.hwActionLabel.font.withSize(25)
            cell.backgroundColor = .gray
        } else {
            cell.hwActionLabel.font = cell.hwActionLabel.font.withSize(17)
            cell.backgroundColor = UIColor(named: "backgrounds")
        }
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (wlqData.getfirmwareVersion() != "Unknown"){
            if (wlqData.getfirmwareVersion().toDouble()! >= 2.0) {
                if (wlqData.keyMode == wlqData.keyMode_custom){
                    if (self.actionID[indexPath.row] != -1){
                        selectedActionID = self.actionID[indexPath.row]
                        performSegue(withIdentifier: "hwSettingsToSettingsAction", sender: [])
                    }
                }
            } else {
                
            }
        }
    }
    
    func updateDisplay(){
        if (wlqData.getfirmwareVersion() != "Unknown"){
            firmwareVersionLabel.text = NSLocalizedString("fw_version_label", comment: "") + " " + wlqData.getfirmwareVersion()
            if (wlqData.getfirmwareVersion().toDouble()! >= 2.0) {      // FW >2.0
                if (wlqData.keyMode == wlqData.keyMode_default || wlqData.keyMode == wlqData.keyMode_custom) {
                    if (wlqData.keyMode == wlqData.keyMode_default){
                        configButton.setTitle(NSLocalizedString("customize_btn_label", comment: ""), for: .normal)
                        configButton.isHidden = false
                        configButton.tag = 2
                    } else if (!wlqData.flashConfig!.elementsEqual(wlqData.tempConfig!)){
                        print("!!!Change detected!!!")
                        configButton.setTitle(NSLocalizedString("config_write_label", comment: ""), for: .normal)
                        configButton.isHidden = false
                        configButton.tag = 1
                    } else if (wlqData.keyMode == wlqData.keyMode_custom){
                        configButton.setTitle(NSLocalizedString("default_btn_label", comment: ""), for: .normal)
                        configButton.isHidden = false
                        configButton.tag = 2
                    } else {
                        configButton.isHidden = true
                    }
                    actionTableLabels = [NSLocalizedString("usb_threshold_label", comment: ""),       //USB
                                         NSLocalizedString("wwMode1", comment: ""),       //Full
                                         NSLocalizedString("long_press_label", comment: ""),
                                         NSLocalizedString("full_scroll_up_label", comment: ""),
                                         NSLocalizedString("full_scroll_down_label", comment: ""),
                                         NSLocalizedString("full_toggle_right_label", comment: ""),
                                         "\(NSLocalizedString("full_toggle_right_label", comment: "")) \(NSLocalizedString("full_long_press_label", comment: ""))",
                                         NSLocalizedString("full_toggle_left_label", comment: ""),
                                         "\(NSLocalizedString("full_toggle_left_label", comment: "")) \(NSLocalizedString("full_long_press_label", comment: ""))",
                                         NSLocalizedString("full_signal_cancel_label", comment: ""),
                                         "\(NSLocalizedString("full_signal_cancel_label", comment: "")) \(NSLocalizedString("full_long_press_label", comment: ""))",
                                         NSLocalizedString("wwMode2", comment: ""),       //RT/K1600
                                         NSLocalizedString("double_press_label", comment: ""),
                                         NSLocalizedString("rtk_page_label", comment: ""),
                                         "\(NSLocalizedString("rtk_page_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                         NSLocalizedString("rtk_zoomp_label", comment: ""),
                                         "\(NSLocalizedString("rtk_zoomp_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                         NSLocalizedString("rtk_zoomm_label", comment: ""),
                                         "\(NSLocalizedString("rtk_zoomm_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                         NSLocalizedString("rtk_speak_label", comment: ""),
                                         "\(NSLocalizedString("rtk_speak_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                         NSLocalizedString("rtk_mute_label", comment: ""),
                                         "\(NSLocalizedString("rtk_mute_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                         NSLocalizedString("rtk_display_label", comment: ""),
                                         "\(NSLocalizedString("rtk_display_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))"]
                                                      
                    var USBThreshold:String = ""
                    if (wlqData.USBVinThreshold == 0x0000){
                        USBThreshold = NSLocalizedString("usbcontrol_on_label", comment: "")
                    } else if (wlqData.USBVinThreshold == 0xFFFF){
                        USBThreshold = NSLocalizedString("usbcontrol_off_label", comment: "")
                    } else {
                        USBThreshold = NSLocalizedString("usbcontrol_engine_label", comment: "")
                    }
                    actionTableMappingLabels = [USBThreshold,   //USB
                                                "",       //Full
                                                "\(wlqData.fullSensitivity!)",
                                                keyboardHID.getKey(action: wlqData.fullScrollUp),
                                                keyboardHID.getKey(action: wlqData.fullScrollDown),
                                                keyboardHID.getKey(action: wlqData.fullToggleRight),
                                                keyboardHID.getKey(action: wlqData.fullToggleRightLongPress),
                                                keyboardHID.getKey(action: wlqData.fullToggleLeft),
                                                keyboardHID.getKey(action: wlqData.fullToggleLeftLongPress),
                                                keyboardHID.getKey(action: wlqData.fullSignalCancel),
                                                keyboardHID.getKey(action: wlqData.fullSignalCancelLongPress),
                                                "",       //RT/K1600
                                                "\(wlqData.RTKSensitivity!)",
                                                keyboardHID.getKey(action: wlqData.RTKPage),
                                                keyboardHID.getKey(action: wlqData.RTKPageDoublePress),
                                                keyboardHID.getKey(action: wlqData.RTKZoomPlus),
                                                keyboardHID.getKey(action: wlqData.RTKZoomPlusDoublePress),
                                                keyboardHID.getKey(action: wlqData.RTKZoomMinus),
                                                keyboardHID.getKey(action: wlqData.RTKZoomMinusDoublePress),
                                                keyboardHID.getKey(action: wlqData.RTKSpeak),
                                                keyboardHID.getKey(action: wlqData.RTKSpeakDoublePress),
                                                keyboardHID.getKey(action: wlqData.RTKMute),
                                                keyboardHID.getKey(action: wlqData.RTKMuteDoublePress),
                                                keyboardHID.getKey(action: wlqData.RTKDisplayOff),
                                                keyboardHID.getKey(action: wlqData.RTKDisplayOffDoublePress)]
                    
                    actionID = [wlqData.USB,    //USB
                                -1,       //Full
                                wlqData.fullLongPressSensitivity,
                                wlqData.fullScrollUp,
                                wlqData.fullScrollDown,
                                wlqData.fullToggleRight,
                                wlqData.fullToggleRightLongPress,
                                wlqData.fullToggleLeft,
                                wlqData.fullToggleLeftLongPress,
                                wlqData.fullSignalCancel,
                                wlqData.fullSignalCancelLongPress,
                                -1,       //RT/K1600
                                wlqData.RTKDoublePressSensitivity,
                                wlqData.RTKPage,
                                wlqData.RTKPageDoublePress,
                                wlqData.RTKZoomPlus,
                                wlqData.RTKZoomPlusDoublePress,
                                wlqData.RTKZoomMinus,
                                wlqData.RTKZoomMinusDoublePress,
                                wlqData.RTKSpeak,
                                wlqData.RTKSpeakDoublePress,
                                wlqData.RTKMute,
                                wlqData.RTKMuteDoublePress,
                                wlqData.RTKDisplayOff,
                                wlqData.RTKDisplayOffDoublePress]
                    
                    if (wlqData.keyMode == wlqData.keyMode_default) { // Default Config
                        modeLabel.text = "\(NSLocalizedString("mode_label", comment: "")) \(NSLocalizedString("keymode_default_label", comment: ""))"
                    } else if (wlqData.keyMode == wlqData.keyMode_custom) { // Custom Config
                        modeLabel.text = "\(NSLocalizedString("mode_label", comment: "")) \(NSLocalizedString("keymode_custom_label", comment: ""))"
                    }
                    modeLabel.isHidden = false
                } else {
                    configButton.setTitle(NSLocalizedString("config_reset_label", comment: ""), for: .normal)
                    modeLabel.isHidden = true
                    configButton.isHidden = false
                    configButton.tag = 0
                }
            } else {            // FW <2.0
                if (wlqData.wheelMode == wlqData.wheelMode_full || wlqData.wheelMode == wlqData.wheelMode_rtk) {
                    if(wlqData.sensitivity != wlqData.tempSensitivity){
                        configButton.setTitle(NSLocalizedString("config_write_label", comment: ""), for: .normal)
                        configButton.isHidden = false
                        configButton.tag = 1
                    } else {
                        if (wlqData.wheelMode == wlqData.wheelMode_full) {
                            configButton.setTitle(NSLocalizedString("wwMode2", comment: ""), for: .normal)
                        } else if (wlqData.wheelMode == wlqData.wheelMode_rtk){
                            configButton.setTitle(NSLocalizedString("wwMode1", comment: ""), for: .normal)
                        }
                        configButton.isHidden = false
                        configButton.tag = 2
                    }
                    if (wlqData.wheelMode == wlqData.wheelMode_full) { //Full
                        modeLabel.text = "\(NSLocalizedString("wwtype_label", comment: "")) \(NSLocalizedString("wwMode1", comment: ""))"
                        actionTableLabels = [NSLocalizedString("double_press_label", comment: ""),
                                             NSLocalizedString("rtk_page_label", comment: ""),
                                             "\(NSLocalizedString("rtk_page_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_zoomp_label", comment: ""),
                                             "\(NSLocalizedString("rtk_zoomp_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_zoomm_label", comment: ""),
                                             "\(NSLocalizedString("rtk_zoomm_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_speak_label", comment: ""),
                                             "\(NSLocalizedString("rtk_speak_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_mute_label", comment: ""),
                                             "\(NSLocalizedString("rtk_mute_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_display_label", comment: ""),
                                             "\(NSLocalizedString("rtk_display_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))"]
                                                           
                        actionTableMappingLabels = ["\(wlqData.sensitivity!)",
                                                    keyboardHID.getKey(action: wlqData.fullScrollUp),
                                                    keyboardHID.getKey(action: wlqData.fullScrollDown),
                                                    keyboardHID.getKey(action: wlqData.fullToggleRight),
                                                    keyboardHID.getKey(action: wlqData.fullToggleRightLongPress),
                                                    keyboardHID.getKey(action: wlqData.fullToggleLeft),
                                                    keyboardHID.getKey(action: wlqData.fullToggleLeftLongPress),
                                                    keyboardHID.getKey(action: wlqData.fullSignalCancel),
                                                    keyboardHID.getKey(action: wlqData.fullSignalCancelLongPress)]
                        
                        actionID = [wlqData.fullLongPressSensitivity,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1]
                    } else if (wlqData.wheelMode == wlqData.wheelMode_rtk) { //RTK1600
                        modeLabel.text = "\(NSLocalizedString("wwtype_label", comment: "")) \(NSLocalizedString("wwMode2", comment: ""))"
                        actionTableLabels = [NSLocalizedString("rtk_page_label", comment: ""),
                                             "\(NSLocalizedString("rtk_page_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_zoomp_label", comment: ""),
                                             NSLocalizedString("rtk_zoomm_label", comment: ""),
                                             NSLocalizedString("rtk_speak_label", comment: ""),
                                             "\(NSLocalizedString("rtk_speak_label", comment: "")) \(NSLocalizedString("rtk_double_press_label", comment: ""))",
                                             NSLocalizedString("rtk_display_label", comment: "")]

                        actionTableMappingLabels = [keyboardHID.getKey(action: wlqData.RTKPage),
                                                    keyboardHID.getKey(action: wlqData.RTKPageDoublePress),
                                                    keyboardHID.getKey(action: wlqData.RTKZoomPlus),
                                                    keyboardHID.getKey(action: wlqData.RTKZoomPlusDoublePress),
                                                    keyboardHID.getKey(action: wlqData.RTKZoomMinus),
                                                    keyboardHID.getKey(action: wlqData.RTKZoomMinusDoublePress),
                                                    keyboardHID.getKey(action: wlqData.RTKSpeak),
                                                    keyboardHID.getKey(action: wlqData.RTKSpeakDoublePress),
                                                    keyboardHID.getKey(action: wlqData.RTKMute),
                                                    keyboardHID.getKey(action: wlqData.RTKMuteDoublePress),
                                                    keyboardHID.getKey(action: wlqData.RTKDisplayOff),
                                                    keyboardHID.getKey(action: wlqData.RTKDisplayOffDoublePress)]
                        actionID = [wlqData.RTKDoublePressSensitivity,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1]
                    }
                    modeLabel.isHidden = false
                    configButton.isHidden = true
                }  else {
                    configButton.setTitle(NSLocalizedString("config_reset_label", comment: ""), for: .normal)
                    modeLabel.isHidden = true
                    configButton.isHidden = false
                    configButton.tag = 0
                }
            }
        }
        self.actionsTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? HWSettingsActionViewController {
            destinationViewController.setup(with: selectedActionID)
        }
    }
    
}
