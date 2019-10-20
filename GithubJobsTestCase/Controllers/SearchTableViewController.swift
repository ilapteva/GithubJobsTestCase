//
//  ViewController.swift
//  GithubJobsTestCase
//
//  Created by Ира on 20/10/2019.
//  Copyright © 2019 Irina Lapteva. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Alamofire
import SwiftyJSON

class SearchTableViewController: UITableViewController {
    
    
    @IBOutlet weak var jobsSearchBar: UISearchBar!
    
    enum GetJobsFailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
    }

    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        jobsSearchBar.rx.text
            .observeOn(MainScheduler.asyncInstance)
            .debounce(.milliseconds(1500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { value in return self.getJobs(searchQuery: value!) }
            .subscribe { (event) in print(event) }
        .disposed(by: disposeBag)
        
        jobsSearchBar.text = "java"
    }
    
    func getJobs(searchQuery: String) -> Observable<JSON> {
        print(searchQuery)
        let url = "https://jobs.github.com/positions.json?search=\(searchQuery)&page=0"
        return Observable.create { observer -> Disposable in
            Alamofire.request(url, method: .get)
                .validate(statusCode: 200..<500)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        guard let data = response.data else {
                            // if no error provided by alamofire return .notFound error instead.
                            // .notFound should never happen here?
                            print(response.error ?? GetJobsFailureReason.notFound)
                            observer.onError(response.error ?? GetJobsFailureReason.notFound)
                            return
                        }
                        do {
                            print(url)
                            let json : JSON = JSON(response.result.value!)
                            //let friends = try JSONDecoder().decode([Job].self, from: data)
                            observer.onNext(json)
                        } catch {
                            print(error)
                            observer.onError(error)
                        }
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode,
                            let reason = GetJobsFailureReason(rawValue: statusCode)
                        {
                            observer.onError(reason)
                        }
                        print(error)
                        observer.onError(error)
                    }
            }
     
            return Disposables.create()
        }
    }

}

//extension SearchTableViewController {
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return items.count
//    }
//
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//
//    }
//}

