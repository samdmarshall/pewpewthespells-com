import strutils
import strtabs
import ospaths
import jester

const PlaintextUserAgents = @[
   "curl",
   "wget",
   "httpie",
   "python-requests"
]

proc wantsPlainTextContent*(request: Request): bool =
  let wants_plaintext = 
    if request.headers.hasKey("Accept"):
      request.headers["Accept"] == "text/plain"
    else:
      false
  var is_plaintext_agent = false
  for match in PlainTextUserAgents:
    is_plaintext_agent = request.headers["User-Agent"].toLower().contains(match)
    if is_plaintext_agent:
      break
  return (wants_plaintext or is_plaintext_agent) and (request.path.endsWith("/") or request.path.endsWith(".html"))


proc getPlainTextForRequest*(request: Request, base_path: string): string =
  var requested_path = request.path
  if request.path.endsWith("/"):
    requested_path &= "index.html"
  requested_path = requested_path.changeFileExt(".txt")
  let content_path = base_path.joinPath(requested_path)
  let plain_file = open(content_path)
  let contents = plain_file.readAll()
  plain_file.close()
  return contents
