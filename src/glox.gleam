import argv
import file_streams/file_stream
import gleam/bit_array
import gleam/erlang
import gleam/int
import gleam/io
import scanner.{type CompileError, Scanner, scan_tokens}

fn run_file(path: String) {
  let assert Ok(stream) = file_stream.open_read(path)
  let assert Ok(byte_content) = stream |> file_stream.read_remaining_bytes()
  let assert Ok(string_content) = byte_content |> bit_array.to_string

  let assert Ok(_) = run(string_content)
}

fn run_prompt() {
  case erlang.get_line("> ") {
    Ok(line) -> {
      let _ = run(line)
      run_prompt()
    }
    Error(e) -> {
      io.println("Error reading line:" <> erlang.format(e))
      panic as "Error reading line"
    }
  }
}

pub fn run(source: String) -> Result(Nil, CompileError) {
  let my_scanner = Scanner(source)

  case scan_tokens(my_scanner) {
    Ok(tokens) -> {
      io.print("Parsed Tokens:")
      io.debug(tokens)
      Ok(Nil)
    }
    Error(e) -> {
      report(e)
      Error(e)
    }
  }
}

fn report(error: CompileError) {
  io.println_error(
    "[line "
    <> error.line |> int.to_string
    <> "] Error"
    <> "todo: where"
    <> ": "
    <> error.message,
  )
}

pub fn main() {
  case argv.load().arguments {
    [] -> run_prompt()
    [file] -> run_file(file)
    _ -> {
      io.println("Usage: glox [script]")
      panic as "Invalid arguments"
    }
  }
}
