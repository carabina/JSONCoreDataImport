#JSON Core Data Import

## Requirements
- iOS 8
- Xcode 8.1+
- Swift 3.0

## Dependency
- Alamofire (https://github.com/Alamofire/Alamofire)
- SwiftyJSON (https://github.com/SwiftyJSON/SwiftyJSON)

## Features
- Truncate and import data for populate a Core Data from a JSON
- During importation, detect and download image
- You can used DispatchGroup for be alerted when donwload is finished

#Example

### Only data : 

- JSON :
```JSON
{
	"EntityName": [{
		"id": 1,
		"name": "Suroh"
	}, {
		"id": 2,
		"name": "Horus"
	}]
}
```
- Code :
```swift
let jsonCoreDataImport = JSONCoreDataImport(delegateClass: self)
jsonCoreDataImport.importJSON(json)
```

###  Data + Image + DispatchGroup : 

- JSON :
```JSON
{
	"EntityName": [{
		"id": 1,
		"name": "Suroh",
		"image": "suroh.png"
	}, {
		"id": 2,
		"name": "Horus",
		"image": "horus.png"
	}]
}
```
- Code :
```swift
let group = DispatchGroup()
let jsonCoreDataImport = JSONCoreDataImport(delegateClass: self)
jsonCoreDataImport.importJSON(json, groupList: group,withImage: true, imageColumnName:"image",urlCDNImage: "http://cdn.mywebsite.fr/")

group.notify(queue: DispatchQueue.main) {
  //called when download is finished
}
```
