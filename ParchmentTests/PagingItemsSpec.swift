import Foundation
import Quick
import Nimble
@testable import Parchment

private struct Item: PagingItem, Equatable {
  let index: Int
  let width: CGFloat
}

private func ==(lhs: Item, rhs: Item) -> Bool {
  return lhs.index == rhs.index && lhs.width == rhs.width
}

class Presentable: PagingItemPresentable {
  
  func widthForPagingItem<T: PagingItem>(pagingItem: T) -> CGFloat {
    guard let item = pagingItem as? Item else { return 0 }
    return item.width
  }
  
}

class DataSource: PagingViewControllerDataSource {
  
  private let items: [Item] = [
    Item(index: 0, width: 50),
    Item(index: 1, width: 100),
    Item(index: 2, width: 50),
    Item(index: 3, width: 100),
    Item(index: 4, width: 50),
    Item(index: 5, width: 100),
    Item(index: 6, width: 50),
    Item(index: 7, width: 100),
    Item(index: 8, width: 50)
  ]
  
  func initialPagingItem() -> PagingItem? {
    return items.first
  }
  
  func pagingItemBeforePagingItem(pagingItem: PagingItem) -> PagingItem? {
    guard let index = items.indexOf(pagingItem as! Item) else { return nil }
    if index > 0 {
      return items[index - 1]
    }
    return nil
  }
  
  func pagingItemAfterPagingItem(pagingItem: PagingItem) -> PagingItem? {
    guard let index = items.indexOf(pagingItem as! Item) else { return nil }
    if index < items.count - 1 {
      return items[index + 1]
    }
    return nil
  }
  
  func viewControllerForPagingItem(pagingItem: PagingItem) -> UIViewController {
    return UIViewController()
  }
  
}

class PagingItemsSpec: QuickSpec {
  
  override func spec() {
    
    let dataSource = DataSource()
    let presentable = Presentable()
    
    describe("PagingItems") {
      
      describe("itemsBefore:") {
        
        it("returns no items before the first item") {
          let items = itemsBefore([Item(index: 0, width: 50)],
                                  width: 150,
                                  dataSource: dataSource,
                                  presentable: presentable)
          expect(items.isEmpty).to(beTrue())
        }
        
        it("returns no items if the width is zero") {
          let items = itemsBefore([Item(index: 4, width: 50)],
                                  width: 0,
                                  dataSource: dataSource,
                                  presentable: presentable)
          expect(items.isEmpty).to(beTrue())
        }
        
        it("only returns the items that can fit within the provided width") {
          let items = itemsBefore([Item(index: 4, width: 50)],
                                  width: 200,
                                  dataSource: dataSource,
                                  presentable: presentable)
          expect(items.count).to(equal(3))
          expect(items[0]).to(equal(Item(index: 1, width: 100)))
          expect(items[1]).to(equal(Item(index: 2, width: 50)))
          expect(items[2]).to(equal(Item(index: 3, width: 100)))
        }
        
        it("stops when the data source returns nil") {
          let items = itemsBefore([Item(index: 1, width: 100)],
                                  width: 500,
                                  dataSource: dataSource,
                                  presentable: presentable)
          expect(items.count).to(equal(1))
          expect(items[0]).to(equal(Item(index: 0, width: 50)))
        }
        
      }
      
      describe("itemsAfter:") {
        
        it("returns no items after the last item") {
          let items = itemsAfter([Item(index: 8, width: 50)],
                                 width: 150,
                                 dataSource: dataSource,
                                 presentable: presentable)
          expect(items.isEmpty).to(beTrue())
        }
        
        it("returns no items if the width is zero") {
          let items = itemsAfter([Item(index: 4, width: 50)],
                                  width: 0,
                                  dataSource: dataSource,
                                  presentable: presentable)
          expect(items.isEmpty).to(beTrue())
        }
        
        it("only returns the items that can fit within the provided width") {
          let items = itemsAfter([Item(index: 4, width: 50)],
                                 width: 200,
                                 dataSource: dataSource,
                                 presentable: presentable)
          expect(items.count).to(equal(3))
          expect(items[0]).to(equal(Item(index: 5, width: 100)))
          expect(items[1]).to(equal(Item(index: 6, width: 50)))
          expect(items[2]).to(equal(Item(index: 7, width: 100)))
        }
        
        it("stops when the data source returns nil") {
          let items = itemsAfter([Item(index: 7, width: 100)],
                                 width: 500,
                                 dataSource: dataSource,
                                 presentable: presentable)
          expect(items.count).to(equal(1))
          expect(items[0]).to(equal(Item(index: 8, width: 50)))
        }
        
      }
      
      describe("visibleItems:") {
        
        it("includes items before and after + the initial item") {
          let items = visibleItems(Item(index: 4, width: 50),
                                   width: 50,
                                   dataSource: dataSource,
                                   presentable: presentable)
          expect(items.count).to(equal(3))
          expect(items[0]).to(equal(Item(index: 3, width: 100)))
          expect(items[1]).to(equal(Item(index: 4, width: 50)))
          expect(items[2]).to(equal(Item(index: 5, width: 100)))
        }
        
      }
      
      describe("widthFromItem:") {
        
        it("accumulates the correct width") {
          let items = [Item(index: 3, width: 100)]
          let dataStructure = PagingDataStructure<Item>(visibleItems: items)
          let width = widthFromItem(Item(index: 0, width: 50),
                                    dataStructure: dataStructure,
                                    dataSource: dataSource,
                                    presentable: presentable)
          expect(width).to(equal(200))
        }
        
        it("returns zero for items already in data structure") {
          let items = [Item(index: 1, width: 100), Item(index: 2, width: 50)]
          let dataStructure = PagingDataStructure<Item>(visibleItems: items)
          
          let firstItemWidth = widthFromItem(Item(index: 1, width: 100),
                                             dataStructure: dataStructure,
                                             dataSource: dataSource,
                                             presentable: presentable)
          
          let lastItemWidth = widthFromItem(Item(index: 1, width: 100),
                                            dataStructure: dataStructure,
                                            dataSource: dataSource,
                                            presentable: presentable)
          
          expect(firstItemWidth).to(equal(0))
          expect(lastItemWidth).to(equal(0))
        }
        
        it("returns zero when there no visible items") {
          let dataStructure = PagingDataStructure<Item>(visibleItems: [])
          let width = widthFromItem(Item(index: 0, width: 50),
                                    dataStructure: dataStructure,
                                    dataSource: dataSource,
                                    presentable: presentable)
          expect(width).to(equal(0))
        }
        
        
      }
     
      describe("diffWidth:") {
        
        it("returns correct width for removed items") {
          
          let from = PagingDataStructure(visibleItems: [
            Item(index: 0, width: 50),
            Item(index: 1, width: 100)
          ])
          
          let to = PagingDataStructure(visibleItems: [
            Item(index: 1, width: 100),
          ])
          
          let width = diffWidth(
            from: from,
            to: to,
            dataSource: dataSource,
            presentable: presentable)
          
          expect(width).to(equal(-50))
        }
        
        it("returns correct width for added items") {
          
          let from = PagingDataStructure(visibleItems: [
            Item(index: 1, width: 100)
          ])
          
          let to = PagingDataStructure(visibleItems: [
            Item(index: 0, width: 50),
            Item(index: 1, width: 100)
          ])
          
          let width = diffWidth(
            from: from,
            to: to,
            dataSource: dataSource,
            presentable: presentable)
          
          expect(width).to(equal(50))
        }
        
      }
      
    }
    
  }

}
