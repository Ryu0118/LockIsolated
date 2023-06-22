import SwiftSyntax

extension FunctionDeclSyntax {
    var functionName: String {
        identifier.text
    }

    var isObjc: Bool {
        !(attributes?
            .compactMap { $0.as(AttributeSyntax.self) }
            .filter {
                $0.attributeName == "objc"
            }
            .isEmpty ?? true
        )
    }

    var isDynamic: Bool {
        !(modifiers?.filter { $0.name.text == "dynamic" }.isEmpty ?? true)
    }
}
