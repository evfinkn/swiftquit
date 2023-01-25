//
//  ViewController.swift
//  Swift Quit
//
//  Created by Johnny Baird on 5/25/22.
//

import Cocoa
import LaunchAtLogin

class ViewController: NSViewController, NSTableViewDelegate, NSWindowDelegate {
    @objc dynamic var launchAtLogin = LaunchAtLogin.kvo
    
    @IBOutlet weak var quitAppsAutomaticallySwitchOutlet: NSSwitch!
    @IBOutlet weak var quitWhichAppsPopupOutlet: NSPopUpButton!
    @IBOutlet weak var quitWhichAppsLabelOutlet: NSTextField!
    @IBOutlet weak var quitAppsWhenPopupOutlet: NSPopUpButton!
    @IBOutlet weak var quitAppsWhenLabelOutlet: NSTextField!
    @IBOutlet weak var includedAppsTableView: NSTableView!
    @IBOutlet weak var excludedAppsTableView: NSTableView!
    @IBOutlet weak var removeIncludedAppButtonOutlet: NSButton!
    @IBOutlet weak var removeExcludedAppButtonOutlet: NSButton!
    
    @IBOutlet weak var launchAtLoginSwitch: NSSwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSApp.activate(ignoringOtherApps: true)
        view.window?.delegate = self
        
        setupViews()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
            
        }
    }
    
    func setupViews() {
        if(swiftQuitSettings["automaticQuitEnabled"] == "true"){
            quitAppsAutomaticallySwitchOutlet.state = NSControl.StateValue.on
            showQuitAppsWhen()
        }
        
        if(swiftQuitSettings["quitWhich"] == "allApps"){
            quitWhichAppsPopupOutlet.title = "All Apps"
        }
        else if(swiftQuitSettings["quitWhich"] == "allExceptExcludedApps"){
            quitWhichAppsPopupOutlet.title = "All Except Excluded Apps"
        }
        else{
            quitWhichAppsPopupOutlet.title = "Only Included Apps"
        }
        
        if(swiftQuitSettings["quitWhen"] == "lastWindowClosed"){
            quitAppsWhenPopupOutlet.title = "Last Window Is Closed"
        }
        else{
            quitAppsWhenPopupOutlet.title = "Any Window Is Closed"
        }
        
        includedAppsTableView.dataSource = self
        includedAppsTableView.delegate = self
        excludedAppsTableView.dataSource = self
        excludedAppsTableView.delegate = self
        
    }
    
    @IBAction func launchAtLoginToggle(_ sender: Any) {
        
        if launchAtLoginSwitch.state == NSControl.StateValue.on {
            SwiftQuit.enableLaunchAtLogin()
        }
        else{
            SwiftQuit.disableLaunchAtLogin()
        }
    }
    
    @IBAction func automaticallyQuitApps(_ sender: Any) {
        
        if quitAppsAutomaticallySwitchOutlet.state == NSControl.StateValue.on {
            showQuitAppsWhen()
            SwiftQuit.enableAutomaticQuit()
            SwiftQuit.activateAutomaticAppClosing()
        }
        else{
            hideQuitAppsWhen()
            SwiftQuit.disableAutomaticQuit()
        }
        
    }
    
    func showQuitAppsWhen(){
        quitAppsWhenPopupOutlet.isEnabled = true
        quitAppsWhenLabelOutlet.textColor = .labelColor
        quitWhichAppsPopupOutlet.isEnabled = true
        quitWhichAppsLabelOutlet.textColor = .labelColor
    }
    
    func hideQuitAppsWhen(){
        quitAppsWhenPopupOutlet.isEnabled = false
        quitAppsWhenLabelOutlet.textColor = .systemGray
        quitWhichAppsPopupOutlet.isEnabled = false
        quitWhichAppsLabelOutlet.textColor = .systemGray
    }
    
    @IBAction func changeQuitWhich(_ sender: Any) {
        
        if(quitWhichAppsPopupOutlet.title == "All Apps"){
            SwiftQuit.enableQuitAllApps()
        }
        else if(quitWhichAppsPopupOutlet.title == "All Except Excluded Apps"){
            SwiftQuit.enableQuitAllExceptExcludedApps()
        }
        else{
            SwiftQuit.enableQuitOnlyIncludedApps()
        }
    }
    
    @IBAction func changeQuitOn(_ sender: Any) {
        
        if(quitAppsWhenPopupOutlet.title == "Last Window Is Closed"){
            SwiftQuit.enableQuitOnLastWindow()
        }
        else{
            SwiftQuit.enableQuitOnAnyWindow()
        }
    }
    
    @IBAction func addIncludedApp(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        let directory = URL(string: "file:///System/Applications/")
        
        dialog.title = "Choose Application"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.treatsFilePackagesAsDirectories = true
        dialog.directoryURL = directory
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                
                swiftQuitIncludedApps.append(result!.path)
                
                let count = swiftQuitIncludedApps.count - 1
                let indexSet = IndexSet(integer:count)
                
                includedAppsTableView.beginUpdates()
                includedAppsTableView.insertRows(at:indexSet, withAnimation:.effectFade)
                includedAppsTableView.endUpdates()
                
                SwiftQuit.updateIncludedApps()
            }
        } else {
            return
        }
    }
    
    @IBAction func removeIncludedApp(_ sender: Any) {
        let row = includedAppsTableView.selectedRow
        
        if (row != -1){
            
            let indexSet = IndexSet(integer:row)
            includedAppsTableView.beginUpdates()
            swiftQuitIncludedApps.remove(at: row)
            includedAppsTableView.removeRows(at:indexSet, withAnimation:.effectFade)
            includedAppsTableView.endUpdates()
            
            if(swiftQuitIncludedApps.isEmpty){
                removeIncludedAppButtonOutlet.isHidden = true
            }
            
            SwiftQuit.updateIncludedApps()
        }
    }
    
    @IBAction func addExcludedApp(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        let directory = URL(string: "file:///System/Applications/")
        
        dialog.title = "Choose Application"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.treatsFilePackagesAsDirectories = true
        dialog.directoryURL = directory
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                
                swiftQuitExcludedApps.append(result!.path)
                
                let count = swiftQuitExcludedApps.count - 1
                let indexSet = IndexSet(integer:count)
                
                excludedAppsTableView.beginUpdates()
                excludedAppsTableView.insertRows(at:indexSet, withAnimation:.effectFade)
                excludedAppsTableView.endUpdates()
                
                SwiftQuit.updateExcludedApps()
            }
        } else {
            return
        }
    }
    
    @IBAction func removeExcludedApp(_ sender: Any) {
        let row = excludedAppsTableView.selectedRow
        
        if(row != -1){
            
            let indexSet = IndexSet(integer:row)
            excludedAppsTableView.beginUpdates()
            swiftQuitExcludedApps.remove(at: row)
            excludedAppsTableView.removeRows(at:indexSet, withAnimation:.effectFade)
            excludedAppsTableView.endUpdates()
            
            if(swiftQuitExcludedApps.isEmpty){
                removeExcludedAppButtonOutlet.isHidden = true
            }
            
            SwiftQuit.updateExcludedApps()
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let excludedSelectionCount = excludedAppsTableView.selectedRowIndexes.count
        if(excludedSelectionCount != 0){
            removeExcludedAppButtonOutlet.isHidden = false
        }
        else{
            removeExcludedAppButtonOutlet.isHidden = true
        }
        
        let includedSelectionCount = includedAppsTableView.selectedRowIndexes.count
        if(includedSelectionCount != 0){
            removeIncludedAppButtonOutlet.isHidden = false
        }
        else{
            removeIncludedAppButtonOutlet.isHidden = true
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if (tableView === includedAppsTableView){
            print("includedAppsTableView")
            return swiftQuitIncludedApps.count
        }
        else{
            print("excludedAppsTableView")
            return swiftQuitExcludedApps.count
        }
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let swiftQuitAppsArray = (tableView === includedAppsTableView)
                               ? swiftQuitIncludedApps
                               : swiftQuitExcludedApps
        let application = swiftQuitAppsArray[row]
        
        let columnIdentifier = tableColumn!.identifier.rawValue
        
        if columnIdentifier == "path" {
            return application
        } else {
            return nil
        }
    }
}
