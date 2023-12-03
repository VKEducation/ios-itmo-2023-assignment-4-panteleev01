import Foundation


let lock = RWLock()

func p(v: Int) {
    lock.writeLock()
    print("task \(v)")
    lock.unlock()
}

func f1() {
    p(v: 1)
}


func f2() {
    p(v: 2)
}

func f3() {
    p(v: 3)
}

func f4() {
    p(v: 4)
}

let t1 = Task(priority: 1, task: f1)
let t2 = Task(priority: 2, task: f2)
let t3 = Task(priority: 3, task: f3)
let t4 = Task(priority: 4, task: f4)

t4.addDependency(t1)
t4.addDependency(t2)
t2.addDependency(t3)

let x = TaskManager(threadCount: 3)
x.add(t4)

x.start()


RunLoop.current.run()




//let ff = ThreadSafeArray<Int>()
//var dd = [1]
//dd.append(1)
//ff.dropFirst()
//
//let sd = ff[0]

