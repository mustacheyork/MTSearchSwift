//
//  ViewController.swift
//  ShopSearch
//
//  Created by Kanako Kobayashi on 2017/01/14.
//  Copyright © 2017年 Swift-Beginners. All rights reserved.
//

import UIKit
import SafariServices
import CoreLocation

class ViewController: UIViewController , UISearchBarDelegate , UITableViewDataSource , UITableViewDelegate , SFSafariViewControllerDelegate, CLLocationManagerDelegate {

  // MovableTypeの定義
  // (下記の定義を必要に応じて書き換えする)
  
  // ホスト名
  let mtHost = "mt.cmshive.info"
  
  // MovableTypeパス
  let mtPath = "mt"
  
  // MovableType SiteID
  let mtSiteID = "1"
  
  // 位置情報サービスのインスタンス
  let locationManager = CLLocationManager()
  
  // 緯度
  var latitude: CLLocationDegrees = 0
  var now_latitude: CLLocationDegrees = 0
  
  // 経度
  var longitude: CLLocationDegrees = 0
  var now_longitude: CLLocationDegrees = 0
  
  // 距離
  var distance: Double = 0.0
  
  // 店舗の緯度
  var map_latitude:  Double = 0.0
  
  // 店舗の経度
  var map_longitude: Double = 0.0
  
  // 店舗情報
  var shop_info: String = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Search Barのdelegate通知先を設定する
    searchText.delegate = self
    
    // 入力のヒントになる、プレースホルダを設定する
    searchText.placeholder = "検索したいキーワードを入力してください"
    
    // Table ViewのdataSourceを設定
    tableView.dataSource = self
    
    // Table Viewのdelegateを設定
    tableView.delegate = self
    
    // 位置情報の通知先を指定
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.startUpdatingLocation()
    }
    
}
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  @IBOutlet weak var searchText: UISearchBar!
  @IBOutlet weak var tableView: UITableView!

  // 店舗情報のリスト（タプル配列）
  var recipeList : [(name:String, link:String, image:String, shop_latitude:String, shop_longtude:String)] = []
  
  // 検索処理
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    // キーボードを閉じる
    view.endEditing(true)
    
    if let searchWord = searchBar.text {
      // 入力値がnilでなかったら、店舗を検索
      searchShop(keyword: searchWord)
    }
  }
  
  // 店舗検索処理
  // 第一引数：keyword 検索したいワード
  func searchShop(keyword : String) {
    // 店舗情報の検索キーワードをURLエンコードする
    let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    
    // URLオブジェクトの生成
    var URL = Foundation.URL(string: "http://\(mtHost)/\(mtPath)/mt-data-api.cgi/v3/search?search=\(keyword_encode!)")
    
    if (keyword.isEmpty) {
        // キーワードがない場合
        URL = Foundation.URL(string: "http://\(mtHost)/\(mtPath)/mt-data-api.cgi/v3/sites/\(mtSiteID)/entries")
    }
    
    // リンクオブジェクトの生成
    let req = URLRequest(url: URL!)
    
    // セッションの接続をカスタマイズできる
    // タイムアウト値、キャッシュポリシーなどが指定できる。今回は、デフォルト値を使用
    let configuration = URLSessionConfiguration.default
    
    // セッション情報を取り出し
    let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
    
    // リクエストをタスクとして登録
    let task = session.dataTask(with: req, completionHandler: {
      (data , request , error) in
      // do try catch エラーハンドリング
      do {
        // 受け取ったJSONデータをパース（解析）して格納します
        let json = try JSONSerialization.jsonObject(with: data!) as! [String:Any]

        // 店舗情報リストを初期化
        self.recipeList.removeAll()
        
        // 店舗の情報が取得できているか確認
        if let items = json["items"] as? [[String:Any]] {
          
          // 取得しているレシピの数だけ処理
          for item in items {

            // 店舗情報
            guard let name = item["title"] as? String else {
              continue
            }
            // 掲載URL
            // urlからlinkに名称を変更しているのでご注意ください
            guard let link = item["permalink"] as? String else {
              continue
            }

            // 画像URL
            var image = ""
            if let assets = item["assets"] as? [[String:Any]] {
                guard let thumnail = assets[0]["url"] as? String else {
                    continue
                }
                image = thumnail
            }
            
            // MTカスタムフィールドから、緯度経度情報を取得
            var shop_latitude = ""
            var shop_longtude = ""
            if let customFields = item["customFields"] as? [[String:Any]] {
              shop_latitude = (customFields[0]["value"] as? String)!
              shop_longtude = (customFields[1]["value"] as? String)!
            }
            
            // 店舗情報をタプルでまとめて管理
            let recipe = (name, link, image, shop_latitude, shop_longtude)
            // 店舗一覧の配列へ追加
            self.recipeList.append(recipe)
            
          }
        }
        
        //Table Viewを更新する
        self.tableView.reloadData()
        
      } catch {
        // エラー処理
        print("エラーが出ました")
      }
    })
    // ダウンロード開始
    task.resume()
  }
  
  // Cellの総数を返すdatasourceメソッド、必ず記述する必要があります
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // 店舗一覧の総数
    return recipeList.count
  }
  
  // Cellに値を設定するdatasourceメソッド。必ず記述する必要があります
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    //今回表示を行う、Cellオブジェクト（１行）を取得する
    let cell = tableView.dequeueReusableCell(withIdentifier: "recipeCell", for: indexPath)
    
    // 店舗情報の設定
    cell.textLabel?.text = "\(recipeList[indexPath.row].name)"
    
    // 店舗の緯度情報
    let go_latitude: Double = Double(recipeList[indexPath.row].shop_latitude)!
    
    // 店舗の経度情報
    let go_longitude: Double = Double(recipeList[indexPath.row].shop_longtude)!
    
    // 現在位置情報
    let now_point: CLLocation = CLLocation(latitude: now_latitude, longitude: now_longitude)
    
    // 行き先位置情報
    let go_point: CLLocation = CLLocation(latitude: go_latitude, longitude: go_longitude)
    
    // 現在地から行き先までの距離
    distance = go_point.distance(from: now_point)
    
    // 距離設定
    cell.detailTextLabel?.text = String(floor(distance)/1000)
    
    // Assets画像のURLを取り出す
    let url = URL(string: recipeList[indexPath.row].image)
    
    // URLから画像を取得
    if let image_data = try? Data(contentsOf: url!) {
      // 正常に取得できた場合は、UIImageで画像オブジェクトを生成して、Cellにレシピ画像を設定
      cell.imageView?.image = UIImage(data: image_data)
    }
    
    // 設定済みのCellオブジェクトを画面に反映
    return cell
  }
  
  // Cellが選択された際に呼び出されるdelegateメソッド
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // 地図に渡す値を取得
    map_latitude = Double(recipeList[indexPath.row].shop_latitude)!
    map_longitude = Double(recipeList[indexPath.row].shop_longtude)!
    shop_info = recipeList[indexPath.row].name
    
    // 地図に画面遷移
    performSegue(withIdentifier: "goMap", sender: nil)
  }
  
  // 地図に渡す値をセットするメソッド
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let MapViewController:MapViewController = segue.destination as! MapViewController
    MapViewController.latitude = map_latitude
    MapViewController.longitude = map_longitude
    MapViewController.shop_info = shop_info
  }
  
  // 位置情報が更新されるたびに呼ばれる
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let newLocation = locations.last else {
      return
    }
       
    now_latitude = newLocation.coordinate.latitude
    now_longitude = newLocation.coordinate.longitude

    //Table Viewを更新する
    self.tableView.reloadData()
  }

  // mark : CLLocation
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

    switch status {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .restricted, . denied:
      // 一覧表示
      searchShop(keyword: "")
    case .authorizedAlways, .authorizedWhenInUse:
      // 一覧表示
      searchShop(keyword: "")
    }
  }
}

