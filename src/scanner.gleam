import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import token.{type Token, Token}
import token_type.{type TokenType, Eof}

pub type Scanner {
  Scanner(source: String)
}

pub type CompileError {
  CompileError(message: String, line: Int)
}

fn keywords() -> Dict(String, TokenType) {
  dict.from_list([
    #("and", token_type.And),
    #("class", token_type.Class),
    #("else", token_type.Else),
    #("false", token_type.FALSE),
    #("for", token_type.For),
    #("fun", token_type.Fun),
    #("if", token_type.If),
    #("nil", token_type.Nil),
    #("or", token_type.Or),
    #("print", token_type.Print),
    #("return", token_type.Return),
    #("super", token_type.Super),
    #("this", token_type.This),
    #("var", token_type.Var),
    #("while", token_type.While),
  ])
}

pub fn scan_tokens(scanner: Scanner) -> Result(List(Token(value)), CompileError) {
  scan_tokens_helper(scanner.source, [], 0)
}

fn scan_tokens_helper(
  source: String,
  out: List(Token(value)),
  line: Int,
) -> Result(List(Token(value)), CompileError) {
  case source {
    "" -> {
      let eof = Token(Eof, "", None, line)
      let reversed_tokens = list.append([eof], out)
      Ok(list.reverse(reversed_tokens))
    }
    "(" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.LeftParen, out, line),
        line,
      )
    ")" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.RightParen, out, line),
        line,
      )
    "{" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.LeftBrace, out, line),
        line,
      )
    "}" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.RightBrace, out, line),
        line,
      )
    "," <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Comma, out, line),
        line,
      )
    "." <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Dot, out, line),
        line,
      )
    "-" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Minus, out, line),
        line,
      )
    "+" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Plus, out, line),
        line,
      )
    ";" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Semicolon, out, line),
        line,
      )
    "*" <> rest ->
      scan_tokens_helper(
        rest,
        add_first_token(source, token_type.Star, out, line),
        line,
      )
    "!" <> rest -> {
      case rest {
        "=" <> rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.BangEqual, out, line),
            line,
          )
        rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.Bang, out, line),
            line,
          )
      }
    }
    "=" <> rest -> {
      case rest {
        "=" <> rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.EqualEqual, out, line),
            line,
          )
        rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.Equal, out, line),
            line,
          )
      }
    }
    "<" <> rest -> {
      case rest {
        "=" <> rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.LessEqual, out, line),
            line,
          )
        rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.Less, out, line),
            line,
          )
      }
    }
    "> " <> rest -> {
      case rest {
        "=" <> rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.GreaterEqual, out, line),
            line,
          )
        rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.Greater, out, line),
            line,
          )
      }
    }
    "/" <> rest -> {
      case rest {
        "/" <> rest2 -> scan_tokens_helper(skip_to_next_line(rest2), out, line)
        rest2 ->
          scan_tokens_helper(
            rest2,
            add_double_token(source, token_type.Slash, out, line),
            line,
          )
      }
    }
    " " <> rest | "\r" <> rest | "\t" <> rest ->
      scan_tokens_helper(rest, out, line)
    "\n" <> rest -> scan_tokens_helper(rest, out, line + 1)
    "\"" <> rest -> {
      case capture_string(rest) {
        Ok(CaptureStringResult(matched, remaining)) ->
          scan_tokens_helper(
            remaining,
            add_token(matched, token_type.String, out, line),
            line,
          )
        Error(e) -> Error(CompileError(e, line))
      }
    }
    c ->
      case is_digit(c) {
        True -> {
          case capture_digits(c) {
            Ok(CaptureStringResult(matched, remaining)) ->
              scan_tokens_helper(
                remaining,
                add_token(matched, token_type.Number, out, line),
                line,
              )
            Error(e) -> Error(CompileError(e, line))
          }
        }
        False -> {
          case is_alpha(c) {
            True ->
              case capture_identifier(c) {
                Ok(CaptureStringResult(matched, remaining)) -> {
                  scan_tokens_helper(
                    remaining,
                    add_token(
                      matched,
                      // Random alpha string can either be a keyword or an identifier
                      keywords()
                        |> dict.get(matched)
                        |> result.unwrap(token_type.Identifier),
                      out,
                      line,
                    ),
                    line,
                  )
                }
                Error(e) -> Error(CompileError(e, line))
              }
            False -> Error(CompileError({ "Invalid token scanned" <> c }, line))
          }
        }
      }
  }
}

fn add_first_token(
  source: String,
  token_type: TokenType,
  out: List(Token(value)),
  line: Int,
) {
  let assert Ok(text) = string.first(source)
  list.append([Token(token_type, text, None, line)], out)
}

fn add_double_token(
  source: String,
  token_type: TokenType,
  out: List(Token(value)),
  line: Int,
) {
  let text = string.slice(source, 0, 2)
  list.append([Token(token_type, text, None, line)], out)
}

fn add_token(
  source: String,
  token_type: TokenType,
  out: List(Token(value)),
  line: Int,
) {
  list.append([Token(token_type, source, None, line)], out)
}

fn skip_to_next_line(source: String) -> String {
  case source {
    "" -> ""
    "\n" <> rest -> rest
    _ -> skip_to_next_line(string.drop_left(source, 1))
  }
}

type CaptureStringResult {
  CaptureStringResult(matched: String, remaining: String)
}

fn capture_string(source: String) -> Result(CaptureStringResult, String) {
  capture_string_helper(source, [])
}

fn capture_string_helper(
  source: String,
  out: List(String),
) -> Result(CaptureStringResult, String) {
  case source {
    "" -> Error("Unterminated string")
    "\"" <> rest ->
      Ok(CaptureStringResult(out |> list.reverse() |> string.concat(), rest))
    _ -> {
      let assert Ok(c) = string.first(source)
      capture_string_helper(string.drop_left(source, 1), list.append([c], out))
    }
  }
}

fn is_alpha(source: String) -> Bool {
  case
    source
    |> string.to_utf_codepoints()
    |> list.first()
    |> result.map(string.utf_codepoint_to_int)
  {
    Ok(c) -> { c >= 97 && c <= 122 } || { c >= 65 && c <= 90 } || { c == 95 }
    Error(_) -> False
  }
}

fn is_alpha_num(source: String) -> Bool {
  is_alpha(source) || is_digit(source)
}

fn capture_identifier(source: String) -> Result(CaptureStringResult, String) {
  capture_identifier_helper(source, [])
}

fn capture_identifier_helper(
  source: String,
  out: List(String),
) -> Result(CaptureStringResult, String) {
  case source {
    "" -> Error("Unterminated identifier")
    s ->
      case is_alpha_num(s) {
        True -> {
          let assert Ok(#(head, rest)) = s |> string.pop_grapheme()
          capture_identifier_helper(rest, list.append([head], out))
        }
        False ->
          Ok(CaptureStringResult(
            out |> list.reverse() |> string.concat(),
            source,
          ))
      }
  }
}

fn capture_digits(source: String) -> Result(CaptureStringResult, String) {
  capture_digits_helper(source, False, [], [])
}

fn capture_digits_helper(
  source: String,
  has_seen_dot: Bool,
  pre: List(String),
  out: List(String),
) -> Result(CaptureStringResult, String) {
  case source {
    "." <> rest -> {
      case is_digit(rest) && !has_seen_dot {
        True -> capture_digits_helper(rest, True, pre, out)
        False -> {
          case has_seen_dot {
            True -> Error("Matching unexpected second dot when parsing number")
            False ->
              Error("Non digit characters found after dot when parsing number")
          }
        }
      }
    }
    rest ->
      case is_digit(rest) {
        True ->
          case has_seen_dot {
            True -> {
              let assert Ok(#(head, rest2)) = rest |> string.pop_grapheme()
              capture_digits_helper(
                rest2,
                has_seen_dot,
                pre,
                list.append([head], out),
              )
            }
            False -> {
              let assert Ok(#(head, rest2)) = rest |> string.pop_grapheme()
              capture_digits_helper(
                rest2,
                has_seen_dot,
                list.append([head], pre),
                out,
              )
            }
          }
        False -> {
          case has_seen_dot {
            True ->
              Ok(CaptureStringResult(
                pre |> list.reverse() |> string.concat()
                  <> "."
                  <> out |> list.reverse() |> string.concat(),
                rest,
              ))
            False ->
              case pre |> list.is_empty() {
                True -> Error("Expected digits for number, but none found")
                False ->
                  Ok(CaptureStringResult(
                    pre |> list.reverse() |> string.concat(),
                    rest,
                  ))
              }
          }
        }
      }
  }
}

fn is_digit(source: String) -> Bool {
  let assert Ok(c) = string.first(source)
  c == "0"
  || c == "1"
  || c == "2"
  || c == "3"
  || c == "4"
  || c == "5"
  || c == "6"
  || c == "7"
  || c == "8"
  || c == "9"
}
