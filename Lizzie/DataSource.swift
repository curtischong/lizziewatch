import UIKit

class DataSource: NSObject, UITableViewDataSource {
    
    var movies = [String]()
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier") as! MarkEventTableViewCell
        
        cell.textLabel?.text = movies[indexPath.row]
        
        return cell
    }
    
}
