import Foundation

class ThreadSafeArray<T>  {
    
    private var array: [T] = []

    private var rwLock = RWLock()
    
    func append(elem: T) {
        rwLock.acquireRead {
            array.append(elem)
        }
    }
    
    func count() -> Int {
        rwLock.acquireRead {
            return array.count
        }
    }
    
    func isEmpty() -> Bool {
        rwLock.acquireRead {
            return array.isEmpty
        }
    }
    
    func dropFirst() -> ArraySlice<T> {
        rwLock.acquireWrite {
            return array.dropFirst()
        }
    }
    
}


extension ThreadSafeArray: RandomAccessCollection {
    typealias Index = Int
    typealias Element = T

    var startIndex: Index { 
        return array.startIndex // always zero, no lock needed
    }
    
    var endIndex: Index {
        rwLock.acquireRead {
            return array.endIndex
        }
    }

    subscript(index: Index) -> Element {
        get {
            rwLock.acquireRead {
                return array[index]
            }
        }
    }

    func index(after i: Index) -> Index {
        rwLock.acquireRead {
            return array.index(after: i)
        }
    }
    
}


extension ThreadSafeArray<Task> {
    
    // returns true if t1 is more important than t2
    func cmp(t1: Task, t2: Task) -> Bool {
        let r1 = t1.isReady()
        let r2 = t2.isReady()
        if (r1 && !r2) {
            return true
        }
        if (!r1) {
            return false
        }
        return t1.priority > t2.priority
    }
    
    // finds task to execute and removes it from the array
    func popTask() -> Task? {
        rwLock.writeLock()
        defer { rwLock.unlock() }
        
        guard var first = array.first else { return nil }
        var maxIndex = 0
        
        
        if (array.count == 1) {
            array = []
            return first
        }
        
        for i in 1...(array.count - 1) {
            if (!cmp(t1: first, t2: array[i])) {
                first = array[i]
                maxIndex = i
            }
        }
        
        if (first.isReady()) {
            array.remove(at: maxIndex)
            return first
        } else {
            return nil
        }
    }
}
