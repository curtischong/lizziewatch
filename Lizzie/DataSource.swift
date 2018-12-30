import UIKit



class DataSource: NSObject, UITableViewDataSource {
    let displayDateFormatter = DateFormatter()

    var markEvents = [Date]()
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return markEvents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier") as! MarkEventTableViewCell
        displayDateFormatter.dateFormat = "MMM d, h:mm a"
        cell.textLabel?.text = displayDateFormatter.string(from: markEvents[indexPath.row])
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.black
        cell.selectionStyle = UITableViewCell.SelectionStyle.none 
        
        return cell
    }
    
}
