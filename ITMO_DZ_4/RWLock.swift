//
//  RWLock.swift
//  ITMO_DZ_4
//
//  Created by Zahar Panteleev on 29.11.2023.
//

import Foundation

class RWLock {
    
    private var lock = pthread_rwlock_t()
    
    public init() {
        guard pthread_rwlock_init(&lock, nil) == 0 else {
            fatalError("could not initialize lock")
        }
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    func acquireRead<T>(action: () -> T) -> T {
        readLock()
        defer { unlock() }
        return action()
    }
    
    func acquireWrite<T>(action: () -> T) -> T {
        writeLock()
        defer { unlock () }
        return action()
    }
    
    @discardableResult
    func writeLock() -> Bool {
        return pthread_rwlock_wrlock(&lock) == 0
    }
    
    @discardableResult
    func readLock() -> Bool {
        return pthread_rwlock_rdlock(&lock) == 0
    }
    
    @discardableResult
    func unlock() -> Bool {
        return pthread_rwlock_unlock(&lock) == 0
    }
    
    
}
