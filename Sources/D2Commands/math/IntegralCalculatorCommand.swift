import Foundation
import Logging
import D2MessageIO
import D2Permissions
import D2NetAPIs

fileprivate let log = Logger(label: "D2Commands.IntegralCalculatorCommand")

public class IntegralCalculatorCommand: StringCommand {
    public let info = CommandInfo(
        category: .math,
        shortDescription: "Solves an integral",
        longDescription: "Solves an integral online and presents a step-by-step solution",
        requiredPermissionLevel: .basic
    )
    private let parser = InfixExpressionParser()
    private let latexRenderer = LatexRenderer()

    public init() {}

    public func invoke(with input: String, output: CommandOutput, context: CommandContext) {
        do {
            let parsedInput = try parser.parse(input)
            guard let integrationVariable = parsedInput.occurringVariables.first else {
                output.append(errorText: "Ambiguous integral due to multiple integration variables")
                return
            }

            IntegralCalculatorQuery(params: DefaultIntegralQueryParams(
                expression: parsedInput.infixICNotation,
                expressionCanonical: parsedInput.prefixFunctionNotation,
                intVar: integrationVariable
            )).perform().listen {
                do {
                    let result = try $0.get()
                    let stepsLatex = result.steps
                        .map { $0.replacingOccurrences(of: "$", with: "") }
                        .joined(separator: "\\\\")
                    self.latexRenderer.renderImage(from: stepsLatex, to: output)
                } catch {
                    output.append(error, errorText: "An asynchronous error occurred while querying the integral calculator: \(error)")
                }
            }
        } catch {
            output.append(error, errorText: "An error occurred while parsing or performing the query")
        }
    }
}
