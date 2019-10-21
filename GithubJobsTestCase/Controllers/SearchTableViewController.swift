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
import SDWebImage


class SearchTableViewController: UITableViewController, UISearchBarDelegate {

    private var currentPage = 0
    private var pageCount = 50
    private var shouldShowLoadingCell = false
    private var isLoading = true
   
    var jobs: [Job] = []
    @IBOutlet weak var jobsSearchBar: UISearchBar!
    
    enum GetJobsFailureReason: Int, Error {
        case unAuthorized = 401
        case notFound = 404
    }

    let disposeBag = DisposeBag()
    
    
    func getJobs(page: Int) -> Observable<[Job]> {
        currentPage = page
        print("load page\(page) for query \(jobsSearchBar.text!)")
        let url = "https://jobs.github.com/positions.json?search=\(jobsSearchBar.text!)&page=\(page)"
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
                            let jobs = try JSONDecoder().decode([Job].self, from: data)
                            print(jobs.count)
                            observer.onNext(jobs)
                        } catch {
                            observer.onError(error)
                        }
                    case .failure(let error):
                        if let statusCode = response.response?.statusCode,
                            let reason = GetJobsFailureReason(rawValue: statusCode)
                        {
                            observer.onError(reason)
                        }
                        observer.onError(error)
                    }
            }
     
            return Disposables.create()
        }
    }

   func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
       searchBar.resignFirstResponder()
       
   }
}

extension SearchTableViewController {

    
    override func viewDidLoad() {
           super.viewDidLoad()
        self.jobsSearchBar.delegate = self
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshJobs), for: .valueChanged)

        refreshControl?.beginRefreshing()
        if (jobsSearchBar.text == nil) {
              jobsSearchBar.text = "java"
        }
        isLoading = true
        jobsSearchBar.rx.text
            .observeOn(MainScheduler.asyncInstance)
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMap { value in return self.getJobs(page: 0) }
            .subscribe { (event) in self.renderJobs(jobsArr: event.element!, refresh: true) }
            .disposed(by: disposeBag)
        
        if (jobsSearchBar.text == nil) {
            jobsSearchBar.text = "ios"
        }
    }
    
    @objc
    private func refreshJobs() {
        currentPage = 0
        isLoading = true;
        getJobs(page: currentPage)
        .subscribe { (event) in self.renderJobs(jobsArr: event.element!, refresh: true) }
    }
    
    private func fetchNextPage() {
        currentPage += 1
        isLoading = true;
        getJobs(page: currentPage)
            .subscribe { (event) in self.renderJobs(jobsArr: event.element!, refresh: false) }
        .disposed(by: disposeBag)
    }
    
    func renderJobs(jobsArr: [Job], refresh: Bool = true) {
        if (refresh) {
            jobs = jobsArr
        } else {
            for job in jobsArr {
                self.jobs.append(job)
            }
        }
        self.shouldShowLoadingCell = jobs.count % self.pageCount == 0 && jobsArr.count != 0

        self.refreshControl?.endRefreshing()
        isLoading = false
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = jobs.count
        return shouldShowLoadingCell ? count + 1 : count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if isLoadingIndexPath(indexPath) {
            return LoadingCell(style: .default, reuseIdentifier: "loading")
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! JobsCell
            
              let job = jobs[indexPath.row]
              
              cell.titleLabel?.text = job.title
              cell.locationLabel?.text = job.location

              if job.company_logo != nil {
                  cell.logoImageView.sd_setImage(with: URL(string: job.company_logo!))
              } else{
                  cell.logoImageView.image = UIImage(named:"no-logo")
              }
              return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let job = jobs[indexPath.row]
        performSegue(withIdentifier: "toDescription", sender: job)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard isLoadingIndexPath(indexPath) else { return }
        if (!isLoading) {
           fetchNextPage()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)  {
        if segue.identifier == "toDescription" {
            if let searchTableViewController = segue.destination as? DescriptionViewController {
                searchTableViewController.job = sender as? Job
            }
        }
    }
    
    private func isLoadingIndexPath(_ indexPath: IndexPath) -> Bool {
        guard shouldShowLoadingCell else { return false }
        return indexPath.row == self.jobs.count
    }
}

