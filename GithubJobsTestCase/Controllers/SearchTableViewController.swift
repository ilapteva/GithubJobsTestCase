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
    
    var jobs: [Job] = []
    @IBOutlet weak var jobsSearchBar: UISearchBar!
    
    enum GetJobsFailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
    }

    let disposeBag = DisposeBag()

    
    func getJobs(searchQuery: String) -> Observable<[Job]> {
        print(searchQuery)
        let url = "https://jobs.github.com/positions.json?search=\(searchQuery)&page=0"
        return Observable.create { observer -> Disposable in
            Alamofire.request(url, method: .get)
                .validate(statusCode: 200..<500)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        guard let data = response.data else {
                            print(response.error ?? GetJobsFailureReason.notFound)
                            observer.onError(response.error ?? GetJobsFailureReason.notFound)
                            return
                        }
                        do {
                            print(url)
//                            let json : JSON = JSON(response.result.value!)
                            let jobs = try JSONDecoder().decode([Job].self, from: data)
                        
                            observer.onNext(jobs)
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

extension SearchTableViewController {
    
    override func viewDidLoad() {
           super.viewDidLoad()
        jobsSearchBar.rx.text
                  .observeOn(MainScheduler.asyncInstance)
                  .debounce(.milliseconds(1500), scheduler: MainScheduler.instance)
                  .distinctUntilChanged()
                  .flatMap { value in return self.getJobs(searchQuery: value!) }
                  .subscribe { (event) in self.printJobLocation(jobsArr: event.element!) }
              .disposed(by: disposeBag)
              
              jobsSearchBar.text = "java"
       }
    
    func printJobLocation (jobsArr: [Job]) {
        jobs = jobsArr
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        let job = jobs[indexPath.row]
        cell.textLabel?.text = job.title
        cell.detailTextLabel?.text = job.location
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toDescription", sender: self)
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

