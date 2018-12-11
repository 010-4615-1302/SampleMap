//현
//  ViewController.swift
//  SampleMap
//
//  Created by 이정현 on 03/12/2018.
//  Copyright © 2018 이정현. All rights reserved.
//

import UIKit
import MapKit
import SwiftyXMLParser


let BASE_URL = "http://openapi.yeongdo.go.kr:8081/openapi-data/service/rest/lodging"

let accommodationDataKeys = ["address", "area", "areavalue", "category", "categoryvalue", "checktime", "content", "count", "date", "daumx", "daumy", "demandDkey", "demandName", "etc", "etcbreakfast", "etccard", "etcreserve", "etcvat", "homepage", "idx", "image1", "image2", "image3", "image4", "image5", "image6", "image7", "imagedetail1", "imagedetail2", "imagedetail3", "imagedetail4", "imagedetail5", "imagedetail6", "imagedetail7", "information", "isno", "licence", "map1", "map2", "map3", "menutype", "mobile", "multifileId", "name", "note", "oldidx", "oldidxv2", "park", "peakdate", "peakday", "phone", "room", "state", "step", "useMaemuldo", "xposition", "yposition", "zone"]


class ViewController: UIViewController, MKMapViewDelegate {

    let ACCESSTOKEN = "OltNJwW%2BLVmOCsTw1XlnBbRFR7JPo9r6vRxFWc0OzXT%2FzFxxHJY80SB5q3wOlLju4iS%2Be1vbnqLHrwtbv6%2B6eg%3D%3D"
    var accommodationList = [Dictionary<String, String>]()
    
    @IBOutlet var accommodationTableView: UITableView!
    @IBOutlet weak var mapview: MKMapView!
    
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 테이블뷰 델리게이트 등록
        self.accommodationTableView.delegate = self
        self.accommodationTableView.dataSource = self
        
//        self.mapViewInit()
        
        self.loadAccommodationMap {
            // 공공 API로부터 받아온 숙소 리스트는 비동기로 별도의 스레드에서 받아왔기 때문에 메인스레드에서 UI 업데이트 진행
            DispatchQueue.main.async {
                self.pinAccommodation()
                self.accommodationTableView.reloadData()
            }
        }
    }
    
    func mapViewInit() {
        // 앱 실행시 지도의 시작위치 결정
        self.mapview.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 36, longitude: 132),
                                                  span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)),
                               animated: true)
    }
    
    func loadAccommodationMap(completion: @escaping () ->()) {
        let urlString = "\(BASE_URL)/list?ServiceKey=\(ACCESSTOKEN)&numOfRows=100&pageNo=&addr=&title=&cate="
        
        if let url = URL(string: urlString) {
            // URLSession을 통해 오픈 API 데이터 요청
            let task = defaultSession.dataTask(with: url) { (data, response, error) in
                let httpResponse  = response as! HTTPURLResponse
                
                // 요청이 성공했을 경우
                if httpResponse.statusCode == 200 {
                    if let data = data {
                        // XML 파싱
                        let xml = XML.parse(data)
                        
                        // 우리가 필요한 숙소 리스트는 XML 구조를 보면 response > body > items > item 에 위치한다
                        for item in xml["response", "body", "items", "item"] {
                            var accommodation = Dictionary<String, String>()
                            
                            for key in accommodationDataKeys {
                                accommodation[key] = item[key].text
//                                    if let text = item[key].text {
//                                        print("\(key) : \(text)")
//                                    } else {
//                                        print("\(key) : nil")
//                                    }
                            }
                            
                            self.accommodationList.append(accommodation)
                        }
                        
                        completion()
                    }
                }
            }
            task.resume()
        }
    }
    
    // 지도에 숙소들을 마커로 표시하는 함수
    func pinAccommodation() {
        var annotationList = [MKAnnotation]()
        
        // API 숙소 리스트를 순회하면서 필요한 정보만 추출하여 배열에 담는다
        for accommodation in self.accommodationList {
            let annotation = MKPointAnnotation()
            annotation.title = accommodation["name"]
            annotation.subtitle = accommodation["categoryvalue"]
            annotation.coordinate.latitude = Double(accommodation["xposition"]!)!
            annotation.coordinate.longitude = Double(accommodation["yposition"]!)!
            
            annotationList.append(annotation)
        }
        
        // 위에서 생성한 배열을 맵뷰에 전달하여 핀들을 보이게 함
        self.mapview.addAnnotations(annotationList)
        
        // 첫번째 핀 위치로 이동
        if let firstPin = annotationList.first {
            self.mapview.setRegion(MKCoordinateRegion(center: firstPin.coordinate,
                                                      span: MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)),
                                   animated: true)
        }
    }

}

// 테이블 뷰 관련 extension
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.accommodationList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell") else {
            // 셀을 제대로 못가져오는 경우에는 일단 빈셀을 만들어서 리턴시킴
            return UITableViewCell()
        }
        
        // 선택한 셀에 대응되는 숙소 항목을 가져온다
        let accommodation = self.accommodationList[indexPath.row]
        cell.textLabel!.text = accommodation["name"]
        
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 선택한 셀에 대응되는 숙소 항목을 가져온다
        let accommodation = self.accommodationList[indexPath.row]
        
        // 숙소항목에 들어있는 좌표로 맵뷰 이동
        self.mapview.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: Double(accommodation["xposition"]!)!,
                                                                                 longitude: Double(accommodation["yposition"]!)!),
                                                  span: MKCoordinateSpan(latitudeDelta: 0.0001,
                                                                         longitudeDelta: 0.0001)),
                               animated: true)
    }
}
