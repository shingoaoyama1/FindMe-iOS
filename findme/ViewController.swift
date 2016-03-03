//
//  ViewController.swift
//  findme
//
//  Created by user on 24/03/15.
//  Copyright (c) 2015 com. All rights reserved.
//

import UIKit
import MessageUI

class ViewController: UIViewController, GMSMapViewDelegate, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var gMap: GMSMapView!
    @IBOutlet weak var gBanner: GADBannerView!
    @IBOutlet weak var switcher: UISegmentedControl!
    @IBOutlet weak var destinationSwitch: UISwitch!
    @IBOutlet weak var messageView: UILabel!
    @IBOutlet weak var trafficButton: UIButton!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var bottomSheet: UIView!
    
    @IBAction func sendMessage(sender: UIBarButtonItem) {
        onSendMessage()
    }
    @IBAction func sendEmail(sender: UIBarButtonItem) {
        onSendEmail()
    }
    @IBAction func copyText(sender: UIBarButtonItem) {
        onCopyText()
    }
    @IBAction func openMenu(sender: UIBarButtonItem) {
        onOpenMenu()
    }
    @IBAction func closeMenu(sender: UIBarButtonItem) {
        onCloseMenu()
    }
    @IBAction func menuTap(sender: UITapGestureRecognizer) {
        onCloseMenu()
    }
    
    @IBAction func showTraffic(sender: UIButton) {
        self.showTraffic()
    }
    @IBAction func switcherChanged(sender: UISegmentedControl) {
        self.didChangeSwitcher()
    }
    
    var firstLocationUpdate_ = false
    var location_: CLLocation? = nil
    var marker_: GMSMarker? = nil
    var latitude_ = -33.868
    var longitude_ = 151.2086
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set up Google Maps
        gMap.myLocationEnabled = true
        gMap.camera = GMSCameraPosition.cameraWithLatitude(latitude_, longitude: longitude_, zoom: 12)
        gMap.settings.compassButton = true
        gMap.settings.myLocationButton = true
        gMap.delegate = self
        
        // Set up Google Ads
        gBanner.adUnitID = "ca-app-pub-1425708758258424/7590842392"
        gBanner.rootViewController = self
        var request = GADRequest()
        request.testDevices = ["7b9764e1de874a5935e71c96f0908a9b"]
        gBanner.loadRequest(request)
        
        // Listen to the myLocation property of Google Map
        gMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        var dic = change as NSDictionary
        location_ = dic.objectForKey(NSKeyValueChangeNewKey) as? CLLocation
        if (!firstLocationUpdate_){
            firstLocationUpdate_ = true
            gMap.camera = GMSCameraPosition.cameraWithTarget((location_?.coordinate)!, zoom: 14)
        }
        if (marker_ == nil){
            latitude_ = (location_?.coordinate.latitude)!
            longitude_ = (location_?.coordinate.longitude)!
            messageView.text = NSString(format: "%f,%f", latitude_, longitude_)
        }
    }
    
   // GMSMapViewDelegate
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
        if (marker_ == nil){
            marker_ = GMSMarker(position: coordinate)
            marker_?.map = gMap
        } else {
            marker_?.position = coordinate
            if (marker_?.map == nil){
                marker_?.map = gMap
            }
        }
        latitude_ = coordinate.latitude
        longitude_ = coordinate.longitude
        messageView.text = String(format: "%f,%f", latitude_, longitude_)
    }
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        if (marker_ != nil){
            marker_?.map = nil
            if (location_ != nil){
                messageView.text = String(format: "%f,%f", (location_?.coordinate.latitude)!, (location_?.coordinate.longitude)!)
            }

        }
    }
    
    // MessageComposeViewControllerDelegate
    func messageComposeViewController(controller: MFMessageComposeViewController!, didFinishWithResult result: MessageComposeResult) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func didChangeSwitcher() {
        // Switch to the type clicked on
        var switchIndex = switcher.selectedSegmentIndex
        switch(switchIndex){
        case 0:
            gMap.mapType = kGMSTypeNormal
            break
        case 1:
            gMap.mapType = kGMSTypeHybrid
            break
        case 2:
            gMap.mapType = kGMSTypeSatellite
            break
        case 3:
            gMap.mapType = kGMSTypeTerrain
            break
        default:
            break
        }
        onCloseMenu()
    }
    
    func showTraffic() {
        if (gMap.trafficEnabled) {
            gMap.trafficEnabled = false
            trafficButton.setTitle("Show Traffic", forState: UIControlState.Normal)
        } else {
            gMap.trafficEnabled = true
            trafficButton.setTitle("Hide Traffic", forState: UIControlState.Normal)
        }
        onCloseMenu()
    }
    
    func onOpenMenu() {
        menuView.hidden = false
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.bottomSheet.frame.origin.y -= 149
        })
    }
    func onCloseMenu() {
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.bottomSheet.frame.origin.y += 149
        }) { (Bool finished) -> Void in
            self.menuView.hidden = true
        }
    }
    
    func onSendMessage() {
        if (MFMessageComposeViewController.canSendText()){
            var message = MFMessageComposeViewController()
            message.messageComposeDelegate = self
            message.recipients = []
            message.body = generateMessageText()
            self.presentViewController(message, animated: true, completion: nil)
        }
    }
    
    func onSendEmail() {
        var uriString = "mailto:?body=" + generateEncodedMessage()
        var data = NSURL(string: uriString)
        var sharedApplication = UIApplication.sharedApplication()
        if (sharedApplication.canOpenURL(data!)){
            sharedApplication.openURL(data!)
        }
    }
    
    func onCopyText() {
        var pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.string = generateMessageText()
        var alert = UIAlertView()
        alert.message = "Text copied"
        alert.show()
        alert.dismissWithClickedButtonIndex(0, animated: true)
    }
    
    func generateEncodedMessage() -> String {
        var messageText = generateMessageText()
        return messageText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }
    
    func generateMessageText() -> String {
        if (destinationSwitch.on){
            return String(format: "Find me at: maps.google.com/maps?daddr=%f,%f  or comgooglemaps://?daddr=%f,%f for ios", latitude_, longitude_, latitude_, longitude_)
        } else {
            return String(format: "Find me at: maps.google.com/maps?q=%f,%f  or comgooglemaps://?q=%f,%f for ios", latitude_, longitude_, latitude_, longitude_)
        }
    }
}

