//
//  MapViewController.swift
//  ShopSearch
//
//  Created by Kanako Kobayashi on 2017/01/14.
//  Copyright © 2017年 Swift-Beginners. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
  
  // 緯度情報
  var latitude:  Double = 0.0
  
  // 経度情報
  var longitude: Double = 0.0
  
  // 店舗情報
  var shop_info: String = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // 位置情報を設定
    let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
      
    // 表示領域を設定
    let span = MKCoordinateSpanMake(0.005, 0.005)
    let region = MKCoordinateRegionMake(coordinate, span)
    let annotation = MKPointAnnotation()
    annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
    
    // 店舗情報をセット
    annotation.title = shop_info
    
    // ピンを立てる
    self.dispMap.setRegion(region, animated:true)
    self.dispMap.addAnnotation(annotation)
      
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBOutlet weak var dispMap: MKMapView!
  
}
