import Foundation

class AtomicCounter {

    private var lock = RWLock()
    private var counter: UInt = 0
    
    func inc() {
        lock.acquireWrite {
            counter += 1
        }
    }

    func decAndTest() -> Bool {
        lock.acquireWrite {
            counter -= 1
            return counter == 0
        }
    }
    
    func isDone() -> Bool {
        lock.acquireRead {
            return counter == 0
        }
    }
}

class AtomicBool {

    private var lock = RWLock()
    private var value: Bool
    
    init(value: Bool) {
        self.value = value
    }
    
    func get() -> Bool {
        lock.acquireRead {
            return self.value
        }
    }
    
    func set(value: Bool) {
        lock.acquireWrite {
            self.value = value
        }
    }
    
    func or(value: Bool) {
        lock.acquireWrite {
            self.value = self.value || value
        }
    }
    
    func ifFalse(task: () -> ()) {
        lock.acquireWrite {
            if (!value) {
                task()
            }
            value = true
        }
    }
}


class Task {
    
    var deps: [Task] = []
    private var nextTasks: [Task] = []
    
    var priority: Int
    private var task: () -> ()
    private var taskCounter: AtomicCounter
    private var added = AtomicBool(value: false)
    private var ready = AtomicBool(value: true)
    private var done = AtomicBool(value: false)
    
    init(priority: Int, task: @escaping () -> ()) {
        self.priority = priority
        self.task = task
        self.taskCounter = AtomicCounter()
    }

    func addDependency(_ task: Task) {
        deps.append(task)
        task.nextTasks.append(self)
        
        ready.set(value: false)
        taskCounter.inc()
    }
    
    func run() {
        done.ifFalse(task: self.task)
        
        nextTasks.forEach { $0.oneDependencyDone() }
    }
    
    func oneDependencyDone() {
        let isReady = taskCounter.decAndTest()
        ready.or(value: isReady)
    }
    
    func isDone() -> Bool {
        return done.get()
    }
    
    func isAdded() -> Bool {
        return added.get()
    }
    
    func isReady() -> Bool {
        return ready.get()
    }
    
    func afterAdded() {
        added.set(value: true)
    }
}

class ManagerThread: Thread {
    
    private let manager: TaskManagerDelegate
    
    init(manager: TaskManagerDelegate) {
        self.manager = manager
    }
    
    override func main() {
        while (true) {
            if (manager.isFinished() || isCancelled) {
                return
            }
            guard let task = manager.popTask() else {
                continue
            }
            task.run()
        }
    }
}

protocol TaskManagerDelegate {
    func  isFinished() -> Bool
    
    func popTask() -> Task?
}

class TaskManager: TaskManagerDelegate {

    private let threadCount: Int
    
    private var tasks = ThreadSafeArray<Task>()
    private var threads: [Thread] = []
    
    init(threadCount: Int) {
        self.threadCount = threadCount
    }
    
    func start() {
        threads = (1...threadCount).map({ i in
            let thread = ManagerThread(manager: self)
            thread.start()
            return thread
        })
    }
    
    func add(_ task: Task) -> Void {
        if (task.isDone() || task.isAdded()) { return }
        
        task.deps.forEach { task in
            add(task)
        }
        tasks.append(elem: task)
        task.afterAdded()
    }

    func stop() {
        threads.forEach { thread in
            thread.cancel()
        }
    }
    
    func isFinished() -> Bool {
        return tasks.isEmpty()
    }
    
    func popTask() -> Task? {
        return tasks.popTask()
    }
}


