import Foundation

@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro LockIsolated() = #externalMacro(module: "LockIsolatedMacroPlugin", type: "LockIsolatedMacro")

@LockIsolated
class Hoge: NSObject {
    var counter = 0

    dynamic func increment() {
        counter += 1
        print(counter)
    }
}
