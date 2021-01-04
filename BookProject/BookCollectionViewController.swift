//
//  BookCollectionViewController.swift
//  BookProject
//
//  Created by Kunal Patil on 1/3/21.
//

import UIKit

class BookCollectionViewController: UICollectionViewController {
    private let reuseIdentifier = "BookCell"
    private var books: [String : [String : String]] = [:]
    private var cloudContentPath: String?
    private let fileManager = FileManager()

    override func viewDidLoad() {
        // the following line will copy the cloud content folder from bundle to documents directory on device. This step won't be necessary once we start fetching content from cloud. This step is just for prototyping.
        copyFolders()
        //***********
        
        readBooksList()
        
    }
}

// Mark:- collection view data source
extension BookCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> BookCell {
        let cell = collectionView
              .dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BookCell
        let index = indexPath.item
        let keysArray = Array(books.keys)
        guard let book = books[keysArray[index]] else { return cell }
        cell.bookKey = keysArray[index]
        cell.title.text = book[KeyConstants.bookName]
        cell.title.sizeToFit()
        
        guard let coverImageName = book[KeyConstants.coverImageName] else { return cell }
        var isDirectory: ObjCBool = false
        let path = cloudContentPath?.appending("/" + keysArray[index])
        guard let bookFolder = path, fileManager.fileExists(atPath: bookFolder, isDirectory: &isDirectory), isDirectory.boolValue else {
            print("book \(String(describing: book[KeyConstants.bookName])) folder does not exist")
            return cell
        }
        let coverImagePath = bookFolder.appending("/" + coverImageName)
        guard fileManager.fileExists(atPath: coverImagePath) else {
            print("book \(String(describing: book[KeyConstants.bookName])) cover image does not exist")
            return cell
        }
        guard let image = UIImage(contentsOfFile: coverImagePath) else {
            print("can't read cover image: \(coverImagePath)")
            return cell
        }
        cell.cover.image = image
        return cell
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
      
    override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return books.keys.count
    }
    
}

// Mark:- collection view delegate
extension BookCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let bookCell = collectionView.cellForItem(at: indexPath) as! BookCell
        let arViewController = BookARViewController()
        arViewController.bookAnchorContentNames = getBookAnchorsDictionary(forBookWithKey: bookCell.bookKey)
        arViewController.bookDirectoryPath = getBookPath(forBookWithKey: bookCell.bookKey)
        present(arViewController, animated: true, completion: nil)
    }
}

// Mark:- layout
private extension BookCollectionViewController {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 150, height: 200)
        }
}

// Mark:- file access
private extension BookCollectionViewController {
    func readBooksList() {
        let pathPlist = cloudContentPath?.appending("/books.plist")
        guard let booksPlist = pathPlist, fileManager.fileExists(atPath: booksPlist), let plist = fileManager.contents(atPath: booksPlist) else {
            print("books plist does not exist")
            return
        }
        if !plist.isEmpty {
            do {
                books = try PropertyListSerialization.propertyList(from: plist, options: .mutableContainersAndLeaves, format: nil) as! [String : [String : String]]
            } catch {
                print("could not read plist into dictionary \(error)")
            }
        }
    }
    
    func copyFolders() {
        let fileManager = FileManager.default

        let documentsUrl = fileManager.urls(for: .documentDirectory,
                                            in: .userDomainMask)

        guard documentsUrl.count != 0 else {
            return // Could not find documents URL
        }

        let finalDatabaseURL = documentsUrl.first!.appendingPathComponent("CloudContent")
        defer { cloudContentPath = finalDatabaseURL.path }
        if !( (try? finalDatabaseURL.checkResourceIsReachable()) ?? false) {
            print("DB does not exist in documents folder")

            let documentsURL = Bundle.main.resourceURL?.appendingPathComponent("CloudContent")

            do {
                if !FileManager.default.fileExists(atPath:(finalDatabaseURL.path))
                {
                    try FileManager.default.createDirectory(atPath: (finalDatabaseURL.path), withIntermediateDirectories: true, attributes: nil)
                }
                copyFiles(pathFromBundle: (documentsURL?.path)!, pathDestDocs: finalDatabaseURL.path)
            } catch let error as NSError {
                print("Couldn't copy file to final location! Error:\(error.description)")
            }

        } else {
            print("Database file found at path: \(finalDatabaseURL.path)")
        }

    }

    func copyFiles(pathFromBundle : String, pathDestDocs: String) {
        let fileManagerIs = FileManager.default
        do {
            let filelist = try fileManagerIs.contentsOfDirectory(atPath: pathFromBundle)
            try? fileManagerIs.copyItem(atPath: pathFromBundle, toPath: pathDestDocs)

            for filename in filelist {
                try? fileManagerIs.copyItem(atPath: "\(pathFromBundle)/\(filename)", toPath: "\(pathDestDocs)/\(filename)")
            }
        } catch {
            print("\nError\n")
        }
    }
    
    func getBookAnchorsDictionary(forBookWithKey bookKey: String) -> [String : [String]] {
        var anchors: [String : [String]] = [:]
        guard let bookPropertiesDict = books[bookKey], let bookName = bookPropertiesDict[KeyConstants.bookName] else {
            print("book with specified key does not exist")
            return anchors
        }
        let path = getBookPath(forBookWithKey: bookKey)
        let anchorsPlist = path.appending("/" + bookName + ".plist")
        guard fileManager.fileExists(atPath: anchorsPlist), let plist = fileManager.contents(atPath: anchorsPlist) else {
            print("anchors plist for \(bookName) does not exist")
            return anchors
        }
        if !plist.isEmpty {
            do {
                anchors = try PropertyListSerialization.propertyList(from: plist, options: .mutableContainersAndLeaves, format: nil) as! [String : [String]]
            } catch {
                print("could not read plist into dictionary \(error)")
            }
        }
        return anchors
    }
    
    func getBookPath(forBookWithKey bookKey: String) -> String {
        var isDirectory: ObjCBool = false
        guard let path = cloudContentPath?.appending("/" + bookKey), fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            print("book directory path is nill or directory does not exist")
            return ""
        }
        return path
    }
}
