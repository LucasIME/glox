import gleam/float
import gleam/list
import gleam/string
import token.{type Token}

pub type ExpressionLiteral {
  NumberLiteral(value: Float)
  StringLiteral(value: String)
}

pub type Expression {
  Binary(left: Expression, operation: Token, right: Expression)
  Grouping(expression: Expression)
  Literal(value: ExpressionLiteral)
  Unary(operator: Token, right: Expression)
}

pub fn to_string(expression: Expression) -> String {
  case expression {
    Binary(left, operator, right) ->
      parenthesize(operator.lexeme, [left, right])
    Grouping(expression) -> parenthesize("group", [expression])
    Literal(value) -> {
      case value {
        NumberLiteral(value) -> float.to_string(value)
        StringLiteral(value) -> value
      }
    }
    Unary(operator, right) -> parenthesize(operator.lexeme, [right])
  }
}

fn parenthesize(name: String, expressions: List(Expression)) {
  let prefix = "(" <> name <> " "
  let suffix = ")"

  let transformed_expressions = expressions |> list.map(to_string)

  prefix <> transformed_expressions |> string.join(" ") <> suffix
}
