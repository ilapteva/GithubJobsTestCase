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

    let disposeBag = DisposeBag()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        jobsSearchBar.rx.text
            .observeOn(MainScheduler.asyncInstance)
            .debounce(.milliseconds(1500), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe {(event) in print(event)
        }
        .disposed(by: disposeBag)
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

